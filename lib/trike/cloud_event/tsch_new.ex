defmodule Trike.CloudEvent.TschNewV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_new.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          addType: String.t(),
          tripType: String.t(),
          scheduledDepartureTime: String.t(),
          scheduledArrivalTime: String.t(),
          ocsRouteId: String.t(),
          originStation: String.t(),
          destinationStation: String.t(),
          previousTripUid: String.t(),
          nextTripUid: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [
    :counter,
    :timestamp,
    :transitLine,
    :tripUid,
    :addType,
    :tripType,
    :scheduledDepartureTime,
    :scheduledArrivalTime,
    :ocsRouteId,
    :originStation,
    :destinationStation,
    :previousTripUid,
    :nextTripUid
  ]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_new.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschNewMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      addType: message.add_type,
      tripType: message.trip_type,
      scheduledDepartureTime: message.sched_dep,
      scheduledArrivalTime: message.sched_arr,
      ocsRouteId: message.ocs_route_id,
      originStation: message.origin_sta,
      destinationStation: message.dest_sta,
      previousTripUid: message.prev_trip_uid,
      nextTripUid: message.next_trip_uid
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschNewMessage do
  alias Trike.CloudEvent.TschNewV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschNewV1.event_type(),
        TschNewV1.specversion(),
        TschNewV1.from_ocs(parsed_event)
      }
    ]
  end
end
