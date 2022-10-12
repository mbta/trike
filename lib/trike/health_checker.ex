defmodule Trike.HealthChecker do
  use GenServer
  require Logger

  @health_check_interval_ms Application.compile_env(:trike, :health_check_interval_ms)

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Logger.info("Started health checker")
    Process.send_after(self(), :check_health, @health_check_interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(
        :check_health,
        %{ranch_ref: ranch_ref, proxy_pid: proxy_pid, connection_string: conn_str} = state
      ) do
    {:memory_used, memory_info} = :recon.info(proxy_pid, :memory_used)
    ranch_info = :ranch.info(ranch_ref)

    Logger.info(
      "Proxy #{inspect(conn_str)} mailbox size: #{inspect(memory_info[:message_queue_len])} ranch.info: #{inspect(ranch_info)}"
    )

    Process.send_after(self(), :check_health, @health_check_interval_ms)

    {:noreply, state}
  end
end
