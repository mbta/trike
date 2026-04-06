defmodule Trike.CloudEvent.TschTagV1 do
  defmodule CarTag do
    @moduledoc """
    A single tag associated with a train car, as part of the payload of
    a com.mbta.ocs.tsch_con.v1 CloudEvent.
    """
    @type t() :: %__MODULE__{
            carNumber: String.t(),
            carNumberDisplay: String.t(),
            tag: String.t()
          }

    @derive Jason.Encoder
    @enforce_keys [:carNumber, :carNumberDisplay, :tag]
    defstruct @enforce_keys
  end

  @moduledoc """
  The data payload of a com.mbta.ocs.tsch_con.v1 CloudEvent.
  """
  @type t() :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitLine: String.t(),
          tripUid: String.t(),
          trainUid: String.t(),
          consistTags: list(String.t()),
          carTags: list(CarTag.t())
        }

  @derive Jason.Encoder
  @enforce_keys [:counter, :timestamp, :transitLine, :tripUid, :trainUid, :consistTags, :carTags]
  defstruct @enforce_keys

  @spec event_type() :: String.t()
  def event_type, do: "com.mbta.ocs.tsch_tag.v1"

  @spec specversion() :: String.t()
  def specversion, do: "1.0"

  @spec from_ocs(OCS.Message.TschTagMessage.t()) :: t()
  def from_ocs(message) do
    %__MODULE__{
      counter: message.counter,
      timestamp: message.timestamp,
      transitLine: message.transitline,
      tripUid: message.trip_uid,
      trainUid: message.train_uid,
      consistTags: message.consist_tags,
      carTags:
        Enum.map(
          message.car_tags,
          fn car_tag ->
            %CarTag{
              carNumber: car_tag.car_number,
              carNumberDisplay: car_tag.car_number_display,
              tag: car_tag.tag
            }
          end
        )
    }
  end
end

defimpl Trike.CloudEvent.Manifest, for: OCS.Message.TschTagMessage do
  alias Trike.CloudEvent.TschTagV1

  def manifest_from_ocs(parsed_event) do
    [
      {
        TschTagV1.event_type(),
        TschTagV1.specversion(),
        TschTagV1.from_ocs(parsed_event)
      }
    ]
  end
end
