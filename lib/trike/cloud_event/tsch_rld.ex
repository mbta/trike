defmodule Trike.CloudEvent.TschRldV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_rld.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:counter, :timestamp, :transitLine]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_rld.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschRldMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschRldMessage do
  alias Trike.CloudEvent.TschRldV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschRldV1.event_type(),
        TschRldV1.specversion(),
        TschRldV1.from_ocs(parsed_event)
      }
    ]
  end
end
