defmodule Trike.CloudEvent.TschLnkV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_lnk.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          previousTripUid: String.t() | nil,
          nextTripUid: String.t() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [
    :counter,
    :timestamp,
    :transitLine,
    :tripUid,
    :previousTripUid,
    :nextTripUid
  ]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_lnk.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschLnkMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      previousTripUid: message.prev_trip_uid,
      nextTripUid: message.next_trip_uid
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschLnkMessage do
  alias Trike.CloudEvent.TschLnkV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschLnkV1.event_type(),
        TschLnkV1.specversion(),
        TschLnkV1.from_ocs(parsed_event)
      }
    ]
  end
end
