defmodule Trike.Proxy do
  use GenServer
  require Logger
  alias Trike.CloudEvent
  alias Trike.Util

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
    socket_formatted = Util.format_socket(socket)
    partition_key = :crypto.hash(:blake2b, socket_formatted)

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
    _events = Enum.map(messages, &CloudEvent.parse(&1, current_time, partition_key))

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
end
