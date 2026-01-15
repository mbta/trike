defmodule OCS.Message.TschDstMessage do
  @moduledoc """
  TSCH DST message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline, :trip_uid, :dest_sta, :ocs_route_id, :sched_arr]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t(),
          trip_uid: String.t(),
          dest_sta: String.t(),
          ocs_route_id: String.t(),
          sched_arr: String.t()
        }
end
