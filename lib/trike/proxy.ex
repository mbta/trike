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
          socket: :gen_tcp.socket() | nil,
          stream: String.t(),
          connection_string: String.t() | nil,
          buffer: binary(),
          received: integer(),
          put_record_fn:
            (Kinesis.stream_name(), binary(), binary() -> {:ok, term()} | {:error, term()}),
          clock: module()
        }

  @enforce_keys [:stream, :put_record_fn, :clock]
  defstruct @enforce_keys ++ [:socket, :connection_string, buffer: "", received: 0]

  @eot <<4>>
  @staleness_check_interval_ms Application.compile_env(:trike, :staleness_check_interval_ms)

  @impl :ranch_protocol
  @spec start_link(any, any, nil | maybe_improper_list | map) ::
          :ignore | {:error, any} | {:ok, pid}
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
    :timer.send_interval(@staleness_check_interval_ms, :staleness_check)

    {:ok,
     %__MODULE__{
       stream: stream,
       put_record_fn: &kinesis_client.put_record/3,
       clock: clock
     }, {:continue, {ref, transport}}}
  end

  @impl GenServer
  def handle_continue({ref, transport}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    connection_string = format_socket(socket)

    Logger.info(["Accepted socket: ", connection_string])

    {:noreply,
     %{
       state
       | socket: socket,
         connection_string: connection_string
     }}
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket, data},
        %{
          buffer: buffer,
          connection_string: connection_string,
          clock: clock,
          stream: stream
        } = state
      ) do
    {messages, rest} = extract(buffer <> data)
    current_time = clock.utc_now()

    messages
    |> Enum.map(&CloudEvent.from_ocs_message(&1, current_time, connection_string))
    |> Enum.each(fn event ->
      case Jason.encode(event) do
        {:ok, event_json} ->
          {:ok, _result} = state.put_record_fn.(stream, connection_string, event_json)

        error ->
          Logger.info(["Failed to encode message: ", inspect(error)])
      end
    end)

    {:noreply, %{state | buffer: rest, received: state.received + 1}}
  end

  def handle_info({:tcp_closed, socket}, %{connection_string: connection_string} = state) do
    Logger.info(["Socket closed: ", connection_string])
    {:stop, :normal, state}
  end

  def handle_info(:staleness_check, %{received: received} = state) do
    Logger.info("Stale Proxy pid=#{inspect(self())}, received=#{received}")

    {:noreply, %{state | received: 0}}
  end

  def handle_info(msg, state) do
    Logger.info(["Proxy received unknown message: ", inspect(msg)])
    {:noreply, state}
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
