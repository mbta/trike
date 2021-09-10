defmodule Trike.CloudEvent do
  @moduledoc """
  Represents a standard CloudEvent as well as a function for creating new
  CloudEvents from OCS messages.
  """

  alias Trike.OcsRawMessage

  @type t() :: %__MODULE__{
          specversion: String.t(),
          type: String.t(),
          source: String.t(),
          id: String.t(),
          partitionkey: String.t(),
          time: DateTime.t(),
          data: OcsRawMessage.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:source, :id, :partitionkey, :time, :data]
  defstruct @enforce_keys ++
              [
                specversion: "1.0",
                type: "com.mbta.ocs.raw_message"
              ]

  @doc """
  Creates a CloudEvent struct given a full OCS message, the current time, and a
  partition key.
  """
  @spec from_ocs_message(binary(), DateTime.t(), String.t()) :: t()
  def from_ocs_message(message, current_time, partition_key) do
    time = message_time(message, current_time)
    id = :crypto.hash(:blake2b, [DateTime.to_iso8601(time), message]) |> Base.encode64()

    %__MODULE__{
      source: "opstech3.mbta.com/trike",
      time: time,
      id: id,
      partitionkey: partition_key,
      data: %OcsRawMessage{
        received_time: current_time,
        raw: message
      }
    }
  end

  @spec message_time(binary(), DateTime.t()) :: DateTime.t()
  defp message_time(message, current_time) do
    [_count, _type, time, _rest] = String.split(message, ",", parts: 4)

    eastern_time = DateTime.shift_zone!(current_time, "America/New_York")

    DateTime.new!(
      DateTime.to_date(eastern_time),
      Time.from_iso8601!(time),
      "America/New_York"
    )
  end
end
