defmodule Trike.Proxy do
  @moduledoc """
  A Ranch protocol that receives TCP packets, extracts OCS messages from them,
  generates a CloudEvent for each message, and forwards the event to Amazon
  Kinesis.
  """
  use GenServer
  require Logger
  alias Trike.CloudEvent

  @behaviour :ranch_protocol

  @type t() :: %__MODULE__{
          socket: :ranch_transport.socket(),
          stream: String.t(),
          partition_key: String.t(),
          buffer: binary()
        }

  defstruct [:socket, :stream, :partition_key, buffer: ""]

  @eot <<4>>

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {ref, transport, opts[:stream]})
  end

  @impl GenServer
  def init({ref, transport, stream}) do
    {:ok, %__MODULE__{}, {:continue, {ref, transport, stream}}}
  end

  @impl GenServer
  def handle_continue({ref, transport, stream}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    socket_formatted = format_socket(socket)
    partition_key = :crypto.hash(:blake2b, socket_formatted) |> Base.encode64()

    Logger.info("Accepted socket: #{socket_formatted}")

    {:noreply, %{state | socket: socket, stream: stream, partition_key: partition_key}}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, buffer: buffer, partition_key: partition_key} = state
      ) do
    {messages, rest} = extract(buffer <> data)
    current_time = DateTime.utc_now()
    events = Enum.map(messages, &CloudEvent.parse(&1, current_time, partition_key))
    Enum.each(events, &Logger.info(Jason.encode!(&1, pretty: true)))

    {:noreply, %{state | buffer: rest}}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info("#{__MODULE__} unknown message: #{inspect(msg)}")
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
