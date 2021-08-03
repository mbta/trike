defmodule Trike.CloudEvent do
  @moduledoc """
  Represents a standard CloudEvent as well as a function for creating new
  CloudEvents from OCS messages.
  """
  @type t() :: %__MODULE__{
          specversion: String.t(),
          type: String.t(),
          source: URI.t(),
          id: String.t(),
          partitionkey: String.t(),
          time: DateTime.t(),
          data: %{
            received_time: DateTime.t(),
            raw: binary()
          }
        }

  @derive Jason.Encoder
  defstruct [
    :source,
    :id,
    :partitionkey,
    :time,
    specversion: "1.0",
    type: "com.mbta.ocs.raw_message",
    data: %{received_time: nil, raw: nil}
  ]

  @spec from_ocs_message(binary(), DateTime.t(), String.t()) :: t()
  def from_ocs_message(message, current_time, partition_key) do
    time = message_time(message, current_time)
    id = :crypto.hash(:blake2b, [DateTime.to_iso8601(time), message]) |> Base.encode64()

    %__MODULE__{
      source: event_source(),
      time: time,
      id: id,
      partitionkey: partition_key,
      data: %{
        received_time: current_time,
        raw: message
      }
    }
  end

  @spec message_time(binary(), DateTime.t()) :: DateTime.t()
  defp message_time(message, current_time) do
    [_count, _type, time, _rest] = String.split(message, ",", parts: 4)
    [hour, minute, second] = String.split(time, ":")

    eastern_time = DateTime.shift_zone!(current_time, "America/New_York")

    DateTime.new!(
      DateTime.to_date(eastern_time),
      Time.new!(hour, minute, second),
      "America/New_York"
    )
  end

  @spec event_source() :: URI.t()
  defp event_source() do
    {:ok, app} = :application.get_application(__MODULE__)

    URI.merge("ocs://opstech3.mbta.com", to_string(app))
  end

  defimpl Jason.Encoder, for: URI do
    def encode(uri, opts) do
      uri
      |> URI.to_string()
      |> Jason.Encode.string(opts)
    end
  end
end
