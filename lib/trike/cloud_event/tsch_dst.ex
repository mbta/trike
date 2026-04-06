defmodule Trike.CloudEvent.TschDstV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_dst.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          destinationStation: String.t(),
          ocsRouteId: String.t(),
          scheduledArrivalTime: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [
    :counter,
    :timestamp,
    :transitLine,
    :tripUid,
    :destinationStation,
    :ocsRouteId,
    :scheduledArrivalTime
  ]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_dst.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschDstMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      destinationStation: message.dest_sta,
      ocsRouteId: message.ocs_route_id,
      scheduledArrivalTime: message.sched_arr
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschDstMessage do
  alias Trike.CloudEvent.TschDstV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschDstV1.event_type(),
        TschDstV1.specversion(),
        TschDstV1.from_ocs(parsed_event)
      }
    ]
  end
end
