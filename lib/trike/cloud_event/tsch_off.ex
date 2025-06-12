defmodule Trike.CloudEvent.TschOffV1 do
  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_off.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          offset: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [
    :counter,
    :timestamp,
    :transitLine,
    :tripUid,
    :offset
  ]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_off.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschOffMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      offset: message.offset
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschOffMessage do
  alias Trike.CloudEvent.TschOffV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschOffV1.event_type(),
        TschOffV1.specversion(),
        TschOffV1.from_ocs(parsed_event)
      }
    ]
  end
end
