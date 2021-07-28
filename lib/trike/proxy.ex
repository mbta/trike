defmodule Trike.Proxy do
  use GenServer
  require Logger
  alias Trike.Util

  @behaviour :ranch_protocol

  @type t() :: %__MODULE__{
          socket: :ranch_transport.socket(),
          stream: String.t()
        }

  defstruct socket: nil, stream: nil

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

    Logger.info("Accepted socket: #{Util.format_socket(socket)}")

    {:noreply, %{state | socket: socket, stream: stream}}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, stream: stream} = state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {:tcp_closed, _socket},
        %{stream: stream} = state
      ) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info("#{__MODULE__} unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
