defmodule Trike.HealthChecker do
  use GenServer
  require Logger

  @interval_ms 5000

  def start_link(pid: pid) do
    GenServer.start_link(__MODULE__, pid: pid)
  end

  @impl true
  def init(pid: pid) do
    Logger.info("Started health checker")
    Process.send_after(self(), :check_health, @interval_ms)
    {:ok, %{pid: pid}}
  end

  @impl true
  def handle_info(:check_health, %{pid: ref} = state) do
    procs = :ranch.procs(ref, :connections)

    Enum.each(procs, fn pid ->
      {:memory_used, memory_info} = :recon.info(pid, :memory_used)
      Logger.info("Proxy #{inspect(pid)} mailbox size: #{inspect(memory_info[:message_queue_len])}")
    end)

    Process.send_after(self(), :check_health, @interval_ms)

    {:noreply, state}
  end
end
