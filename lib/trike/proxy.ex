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
          partition_key: String.t() | nil,
          buffer: binary(),
          received: integer(),
          put_record_fn:
            (Kinesis.stream_name(), binary(), binary() -> {:ok, term()} | {:error, term()}),
          clock: module()
        }

  @enforce_keys [:stream, :put_record_fn, :clock]
  defstruct @enforce_keys ++ [:socket, :partition_key, buffer: "", received: 0]

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
    {:ok,
     %__MODULE__{
       stream: stream,
       put_record_fn: &kinesis_client.put_record/3,
       clock: clock
     }, {:continue, {:continue_init, ref, transport}}}
  end

  @impl GenServer
  def handle_continue({:continue_init, ref, transport}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    connection_string = format_socket(socket)

    Logger.info(["Accepted socket: ", connection_string])

    children = [
      {Trike.HealthChecker,
       %{ranch_ref: ref, proxy_pid: self(), connection_string: connection_string}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    {:noreply,
     %{
       state
       | socket: socket,
         partition_key: connection_string
     }}
  end

  @impl GenServer
  def handle_info(
        {:tcp, _socket, data},
        %{
          buffer: buffer,
          partition_key: partition_key,
          clock: clock,
          stream: stream
        } = state
      ) do
    {messages, rest} = extract(buffer <> data)
    current_time = clock.utc_now()

    messages
    |> Enum.map(&CloudEvent.from_ocs_message(&1, current_time, partition_key))
    |> Enum.each(fn event ->
      case Jason.encode(event) do
        {:ok, event_json} ->
          {:ok, _result} = state.put_record_fn.(stream, partition_key, event_json)

        error ->
          Logger.info(["Failed to encode message: ", inspect(error)])
      end
    end)

    {:noreply, %{state | buffer: rest, received: state.received + 1}}
  end

  # work around Hackney :ssl_closed bug
  def handle_info({:ssl_closed, _socket}, state) do
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info(["Socket closed: ", inspect(state.partition_key)])
    {:stop, :normal, state}
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
