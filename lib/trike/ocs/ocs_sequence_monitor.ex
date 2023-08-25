defmodule Trike.OCS.SequenceMonitor do
  use GenServer
  require Logger

  @type t() :: %__MODULE__{
          ocs_sequence_by_ip: map()
        }

  defstruct ocs_sequence_by_ip: %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: :ocs_sequence_monitor)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_info({:update, peer_ip, first_sequence_number, last_sequence_number, date}, state) do
    if Map.has_key?(state.ocs_sequence_by_ip, peer_ip) do
      {old_first_sequence_number, old_last_sequence_number, old_date} =
        state.ocs_sequence_by_ip[peer_ip]

      if date == old_date do
        if String.to_integer(old_last_sequence_number) + 1 !=
             String.to_integer(first_sequence_number) do
          Logger.warn(
            "ocs_sequence_monitor event=missing_sequence peer_ip=#{peer_ip} first_sequence_number=#{first_sequence_number} last_sequence_number=#{last_sequence_number} peer_ip=#{peer_ip} old_first_sequence_number=#{old_first_sequence_number} old_last_sequence_number=#{old_last_sequence_number}"
          )
        end
      end
    end

    if first_sequence_number != "" and last_sequence_number != "" do
      Logger.info(
        "ocs_sequence_monitor event=update peer_ip=#{peer_ip} first_sequence_number=#{first_sequence_number} last_sequence_number=#{first_sequence_number}"
      )

      ocs_sequence_by_ip =
        if Map.has_key?(state.ocs_sequence_by_ip, peer_ip),
          do: %{
            state.ocs_sequence_by_ip
            | peer_ip => {first_sequence_number, last_sequence_number, date}
          },
          else:
            Map.put(
              state.ocs_sequence_by_ip,
              peer_ip,
              {first_sequence_number, last_sequence_number, date}
            )

      {:noreply, %{state | ocs_sequence_by_ip: ocs_sequence_by_ip}}
    else
      {:noreply, state}
    end
  end
end
