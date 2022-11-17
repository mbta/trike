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
          put_record_fn:
            (Kinesis.stream_name(), binary(), binary() -> {:ok, term()} | {:error, term()}),
          clock: module()
        }

  @enforce_keys [:stream, :put_record_fn, :clock]
  defstruct @enforce_keys ++
              [
                :transport,
                :socket,
                :partition_key,
                buffer: "",
                last_sequence_number: nil
              ]

  @eot <<4>>

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {
      ref,
      transport,
      opts[:stream],
      opts[:kinesis_client],
      opts[:clock]
    })
  end

  @impl GenServer
  def init({ref, transport, stream, kinesis_client, clock}) do
    Process.flag(:trap_exit, true)

    {:ok,
     %__MODULE__{
       stream: stream,
       put_record_fn: &kinesis_client.put_record/4,
       clock: clock
     }, {:continue, {:continue_init, ref, transport}}}
  end

  @impl GenServer
  def handle_continue({:continue_init, ref, transport}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    Logger.metadata(socket: inspect(socket))
    :ok = transport.setopts(socket, active: :once, buffer: 131_072)
    connection_string = format_socket(socket)

    Logger.info("Accepted socket: conn=#{inspect(connection_string)}")

    {:noreply,
     %{
       state
       | transport: transport,
         socket: socket,
         partition_key: connection_string
     }}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{
          socket: socket
        } = state
      ) do
    {:ok, buffer, sequence_number} = handle_data(state, data)

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

  @spec handle_data(t(), binary()) :: {:ok, binary(), String.t()}
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
        {:ok, rest, last_sequence_number}
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

        Logger.info(
          "put_record_timing stream=#{stream} pkey=#{inspect(partition_key)} length=#{records_length} size=#{byte_size(encoded)} msec=#{div(usec, 1000)} result=#{result_key}"
        )

        {:ok, %{"SequenceNumber" => last_sequence_number}} = result
        {:ok, rest, last_sequence_number}
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
    with {:ok, {local_ip, local_port}} <- :inet.sockname(sock),
         {:ok, {peer_ip, peer_port}} <- :inet.peername(sock) do
      "{#{:inet.ntoa(local_ip)}:#{local_port} -> #{:inet.ntoa(peer_ip)}:#{peer_port}}"
    else
      unexpected -> inspect(unexpected)
    end
  end
end
