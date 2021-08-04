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
          socket: :gen_tcp.socket(),
          stream: String.t(),
          partition_key: String.t(),
          buffer: binary(),
          kinesis_client: module()
        }

  defstruct [:socket, :stream, :partition_key, :kinesis_client, buffer: ""]

  @eot <<4>>

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {ref, transport, opts[:stream], opts[:kinesis_client]})
  end

  @impl GenServer
  def init({ref, transport, stream, client}) do
    {:ok, %__MODULE__{}, {:continue, {ref, transport, stream, client}}}
  end

  @impl GenServer
  def handle_continue({ref, transport, stream, client}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    connection_string = format_socket(socket)
    partition_key = :crypto.hash(:blake2b, connection_string) |> Base.encode64()

    Logger.info("Accepted socket: #{connection_string}")

    {:noreply,
     %{
       state
       | socket: socket,
         stream: stream,
         partition_key: partition_key,
         kinesis_client: client
     }}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{
          socket: socket,
          buffer: buffer,
          partition_key: partition_key,
          kinesis_client: kinesis_client,
          stream: stream
        } = state
      ) do
    {messages, rest} = extract(buffer <> data)
    current_time = DateTime.utc_now()
    events = Enum.map(messages, &CloudEvent.from_ocs_message(&1, current_time, partition_key))

    Enum.each(
      events,
      &kinesis_client.put_record(stream, &1.partitionkey, Jason.encode!(&1))
    )

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
