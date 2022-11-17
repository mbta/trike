defmodule Trike.HealthChecker do
  @moduledoc """
  Periodically logs health information about a Proxy and the Ranch listener.
  """
  use GenServer
  require Logger

  @enforce_keys [:ranch_ref]
  defstruct @enforce_keys

  @type state :: %__MODULE__{
          ranch_ref: String.t()
        }

  @health_check_interval_ms Application.compile_env(:trike, :health_check_interval_ms)

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    {init_opts, server_opts} = Keyword.split(opts, [:ranch_ref])
    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl true
  def init(opts) do
    Logger.info("Started health checker")

    ranch_ref = Keyword.get(opts, :ranch_ref)

    if ranch_ref != nil do
      state = %__MODULE__{
        ranch_ref: ranch_ref
      }

      Process.send_after(self(), :check_health, @health_check_interval_ms)
      {:ok, state}
    else
      Logger.warn("missing state arg in health_checker")
      {:stop, :missing_arg}
    end
  end

  @impl true
  def handle_info(
        :check_health,
        %{ranch_ref: ranch_ref} = state
      ) do
    log_ranch_info(ranch_ref)
    Process.send_after(self(), :check_health, @health_check_interval_ms)

    {:noreply, state}
  end

  @doc """
  Logs relevant information about the given Ranch process:

  - everything from `:ranch.info/1`
  - for each connected process, the message queue size
  """
  @spec log_ranch_info(term()) :: :ok
  def log_ranch_info(ranch_ref) do
    ranch_info = :ranch.info(ranch_ref)

    Logger.info("health_check ranch_info=#{inspect(ranch_info)}")

    for proxy_pid <- :ranch.procs(ranch_ref, :connections) do
      %{partition_key: connection_string} = :sys.get_state(proxy_pid)
      {_, message_queue_len} = :erlang.process_info(proxy_pid, :message_queue_len)

      Logger.info(
        "health_check Proxy proxy_pid=#{inspect(proxy_pid)} conn=#{inspect(connection_string)} mailbox_size=#{message_queue_len}"
      )
    end

    :ok
  end
end
