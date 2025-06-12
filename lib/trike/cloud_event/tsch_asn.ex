defmodule Trike.CloudEvent.TschAsnV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_asn.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          trainUid: String.t(),
          tripUid: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:counter, :timestamp, :transitLine, :trainUid, :tripUid]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_asn.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschAsnMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      trainUid: message.train_uid,
      tripUid: message.trip_uid
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschAsnMessage do
  alias Trike.CloudEvent.TschAsnV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschAsnV1.event_type(),
        TschAsnV1.specversion(),
        TschAsnV1.from_ocs(parsed_event)
      }
    ]
  end
end
