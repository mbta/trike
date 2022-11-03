defmodule Trike.HealthChecker do
  @moduledoc """
  Periodically logs health information about a Proxy and the Ranch listener.
  """
  use GenServer
  require Logger

  @enforce_keys [:ranch_ref, :proxy_pid, :connection_string]
  defstruct @enforce_keys

  @type state :: %__MODULE__{
          ranch_ref: String.t(),
          proxy_pid: pid(),
          connection_string: String.t()
        }

  @health_check_interval_ms Application.compile_env(:trike, :health_check_interval_ms)

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    {init_opts, server_opts} = Keyword.split(opts, [:ranch_ref, :proxy_pid, :connection_string])
    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl true
  def init(opts) do
    Logger.info("Started health checker")

    ranch_ref = Keyword.get(opts, :ranch_ref)
    proxy_pid = Keyword.get(opts, :proxy_pid)
    connection_string = Keyword.get(opts, :connection_string)

    if ranch_ref != nil and proxy_pid != nil and connection_string != nil do
      state = %{
        ranch_ref: ranch_ref,
        proxy_pid: proxy_pid,
        connection_string: connection_string
      }

      Process.send_after(self(), :check_health, @health_check_interval_ms)
      {:ok, state}
    else
      Logger.warn("missing state arg in health_checker")
      :ignore
    end
  end

  @impl true
  def handle_info(
        :check_health,
        %{ranch_ref: ranch_ref, proxy_pid: proxy_pid, connection_string: conn_str} = state
      ) do
    {:memory_used, memory_info} = :recon.info(proxy_pid, :memory_used)
    ranch_info = :ranch.info(ranch_ref)

    Logger.info(
      "health_check Proxy #{inspect(conn_str)} mailbox size: #{inspect(memory_info[:message_queue_len])} ranch.info: #{inspect(ranch_info)}"
    )

    Process.send_after(self(), :check_health, @health_check_interval_ms)

    {:noreply, state}
  end
end
