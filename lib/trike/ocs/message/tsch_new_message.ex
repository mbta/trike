defmodule OCS.Message.TschNewMessage do
  @moduledoc """
  TSCH NEW message type from OCS system
  """
  defstruct [
    :counter,
    :timestamp,
    :transitline,
    :trip_uid,
    :add_type,
    :trip_type,
    :sched_dep,
    :sched_arr,
    :ocs_route_id,
    :origin_sta,
    :dest_sta,
    :prev_trip_uid,
    :next_trip_uid
  ]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t(),
          trip_uid: String.t(),
          add_type: String.t(),
          trip_type: String.t(),
          sched_dep: DateTime.t() | nil,
          sched_arr: DateTime.t() | nil,
          ocs_route_id: String.t() | nil,
          origin_sta: String.t() | nil,
          dest_sta: String.t() | nil,
          prev_trip_uid: String.t() | nil,
          next_trip_uid: String.t() | nil
        }
end
