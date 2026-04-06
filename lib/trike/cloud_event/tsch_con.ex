defmodule Trike.CloudEvent.TschConV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_con.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          consist: [String.t()],
          trainUid: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:counter, :timestamp, :transitLine, :consist, :trainUid]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_con.v1"
  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschConMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      consist: message.consist,
      trainUid: message.train_uid
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschConMessage do
  alias Trike.CloudEvent.TschConV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschConV1.event_type(),
        TschConV1.specversion(),
        TschConV1.from_ocs(parsed_event)
      }
    ]
  end
end
