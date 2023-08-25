defmodule Trike.Proxy do
  @moduledoc """
  A Ranch protocol that receives TCP packets, extracts OCS messages from them,
  generates a CloudEvent for each message, and forwards the event to Amazon
  Kinesis.
  """
  use GenServer
  require Logger
  alias ExAws.Kinesis
  alias Trike.CloudEvent

  @behaviour :ranch_protocol

  @type t() :: %__MODULE__{
          transport: atom,
          socket: :gen_tcp.socket() | nil,
          stream: String.t(),
          partition_key: String.t() | nil,
          buffer: binary(),
          last_sequence_number: String.t() | nil,
          stale_timeout_ms: non_neg_integer(),
          stale_timeout_ref: reference() | nil,
          put_record_fn:
            (Kinesis.stream_name(), binary(), binary() -> {:ok, term()} | {:error, term()}),
          clock: module(),
          ranch: module()
        }

  @enforce_keys [:stream, :put_record_fn, :clock]
  defstruct @enforce_keys ++
              [
                :transport,
                :socket,
                :partition_key,
                :stale_timeout_ref,
                :stale_timeout_ms,
                buffer: "",
                ranch: :ranch,
                last_sequence_number: nil
              ]

  @eot <<4>>

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    opts = Keyword.take(opts, [:stream, :kinesis_client, :clock, :stale_timeout_ms])

    GenServer.start_link(__MODULE__, {
      ref,
      transport,
      opts
    })
  end

  @impl GenServer
  def init({ref, transport, opts}) do
    Process.flag(:trap_exit, true)

    kinesis_client = opts[:kinesis_client]

    {:ok,
     %__MODULE__{
       transport: transport,
       stream: opts[:stream],
       put_record_fn: &kinesis_client.put_record/4,
       stale_timeout_ms:
         Keyword.get(opts, :state_timeout_ms, Application.get_env(:trike, :stale_timeout_ms)),
       clock: opts[:clock]
     }, {:continue, {:continue_init, ref}}}
  end

  @impl GenServer
  def handle_continue({:continue_init, ref}, state) do
    {:ok, socket} = state.ranch.handshake(ref)
    Logger.metadata(socket: inspect(socket))
    :ok = state.transport.setopts(socket, active: :once, buffer: 131_072, keepalive: true)
    connection_string = format_socket(socket)

    Logger.info("Accepted socket: conn=#{inspect(connection_string)}")

    state = %{state | socket: socket, partition_key: connection_string}
    state = schedule_stale_timeout(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{
          socket: socket
        } = state
      ) do
    {:ok, buffer, sequence_number, first_ocs_sequence_number, last_ocs_sequence_number, date} =
      handle_data(state, data)

    with socket when is_port(socket) <- socket,
         {:ok, {peer_ip, _peer_port}} <- :inet.peername(socket) do
      peer_ip_serialized = Enum.join(Tuple.to_list(peer_ip), ".")

      Kernel.send(
        :ocs_sequence_monitor,
        {:update, peer_ip_serialized, first_ocs_sequence_number, last_ocs_sequence_number, date}
      )
    else
      unexpected -> inspect(unexpected)
    end

    state = schedule_stale_timeout(state)

    state.transport.setopts(socket, active: :once)

    {:noreply,
     %{
       state
       | buffer: buffer,
         last_sequence_number: sequence_number
     }}
  end

  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    Logger.info("Socket closed conn=#{inspect(state.partition_key)}")
    {:stop, :normal, state}
  end

  def handle_info({:stale_timeout, socket}, %{socket: socket} = state) do
    Logger.info(
      "Socket stale, closing conn=#{inspect(state.partition_key)} stale_timeout_ms=#{state.stale_timeout_ms}"
    )

    state.transport.close(state.socket)

    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info(["Proxy received unknown message: ", inspect(msg)])
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    Logger.info("Terminating")
    state.transport.close(state.socket)
    {:ok, state}
  end

  @spec handle_data(t(), binary()) ::
          {:ok, binary(), String.t(), String.t(), String.t(), Date.t()}
  defp handle_data(state, data) do
    %{
      buffer: buffer,
      partition_key: partition_key,
      clock: clock,
      stream: stream,
      last_sequence_number: last_sequence_number
    } = state

    current_time = clock.utc_now()

    Logger.metadata(request_id: :erlang.unique_integer([:positive]))
    Logger.info("got_data size=#{byte_size(data)} buf_size=#{byte_size(buffer)}")
    {messages, rest} = extract(buffer <> data)

    records =
      messages
      |> Enum.map(&CloudEvent.from_ocs_message(&1, current_time, partition_key))

    result =
      if records == [] do
        {:ok, rest, last_sequence_number, "", "", get_eastern_tz_date()}
      else
        records_length = length(records)
        encoded = Jason.encode!(records)

        opts =
          if last_sequence_number do
            [sequence_number_for_ordering: last_sequence_number]
          else
            []
          end

        {usec, {result_key, _} = result} =
          :timer.tc(state.put_record_fn, [
            stream,
            partition_key,
            encoded,
            opts
          ])

        Enum.each(
          records,
          &Logger.info("ocs_event raw=#{inspect(&1.data.raw)} time=#{inspect(&1.time)}")
        )

        # Grab our first and last OCS sequence numbers:
        first_ocs_message = Enum.at(records, 0)
        first_ocs_sequence_number = first_ocs_message.data.raw |> String.split(",") |> Enum.at(0)
        last_ocs_message = Enum.at(records, -1)
        last_ocs_sequence_number = last_ocs_message.data.raw |> String.split(",") |> Enum.at(0)

        # Get current date, in Eastern timezone:
        current_date = get_eastern_tz_date()

        Logger.info(
          "put_record_timing stream=#{stream} pkey=#{inspect(partition_key)} length=#{records_length} size=#{byte_size(encoded)} msec=#{div(usec, 1000)} result=#{result_key}"
        )

        {:ok, %{"SequenceNumber" => last_sequence_number}} = result

        {:ok, rest, last_sequence_number, first_ocs_sequence_number, last_ocs_sequence_number,
         current_date}
      end

    Logger.metadata(request_id: nil)
    result
  end

  @spec extract(binary()) :: {[binary()], binary()}
  defp extract(buffer) do
    statements = String.split(buffer, @eot)
    {messages, [rest]} = Enum.split(statements, -1)
    {messages, rest}
  end

  @spec format_socket(:gen_tcp.socket()) :: String.t()
  defp format_socket(sock) do
    with sock when is_port(sock) <- sock,
         {:ok, {local_ip, local_port}} <- :inet.sockname(sock),
         {:ok, {peer_ip, peer_port}} <- :inet.peername(sock) do
      "{#{:inet.ntoa(local_ip)}:#{local_port} -> #{:inet.ntoa(peer_ip)}:#{peer_port}}"
    else
      unexpected -> inspect(unexpected)
    end
  end

  @spec schedule_stale_timeout(t()) :: t()
  defp schedule_stale_timeout(%{stale_timeout_ref: nil} = state) do
    ref = Process.send_after(self(), {:stale_timeout, state.socket}, state.stale_timeout_ms)
    %{state | stale_timeout_ref: ref}
  end

  defp schedule_stale_timeout(state) do
    # already scheduled, cancel and reschedule
    Process.cancel_timer(state.stale_timeout_ref)
    schedule_stale_timeout(%{state | stale_timeout_ref: nil})
  end

  defp get_eastern_tz_date do
    {:ok, current_datetime} = DateTime.now("America/New_York")
    DateTime.to_date(current_datetime)
  end
end
