defmodule Trike.CloudEvent.TschDelV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_del.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          # TODO: Does Jason encoder handle this?
          deleteStatus: :deleted | :undeleted
        }

  @derive Jason.Encoder
  @enforce_keys [:counter, :timestamp, :transitLine, :tripUid, :deleteStatus]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_del.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschDelMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      deleteStatus: message.delete_status
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschDelMessage do
  alias Trike.CloudEvent.TschDelV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschDelV1.event_type(),
        TschDelV1.specversion(),
        TschDelV1.from_ocs(parsed_event)
      }
    ]
  end
end
