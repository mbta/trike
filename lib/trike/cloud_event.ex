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
  @enforce_keys [:id, :partitionkey, :time, :data]
  defstruct @enforce_keys ++
              [
                source: "opstech3.mbta.com/trike",
                specversion: "1.0",
                type: "com.mbta.ocs.raw_message"
              ]

  @doc """
  Creates a CloudEvent struct given a full OCS message, the current time, and a
  partition key.
  """
  @spec from_ocs_message(binary(), DateTime.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def from_ocs_message(message, current_time, partition_key) do
    case message_time(message, current_time) do
      {:ok, time} ->
        id = :crypto.hash(:blake2b, [DateTime.to_iso8601(time), message]) |> Base.encode64()

        {:ok,
         %__MODULE__{
           time: time,
           id: id,
           partitionkey: partition_key,
           data: %OcsRawMessage{
             received_time: current_time,
             raw: message
           }
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec message_time(binary(), DateTime.t()) :: {:ok, DateTime.t()} | {:error, term()}
  defp message_time(message, current_time) do
    with [_count, _type, raw_time, _rest] <- String.split(message, ",", parts: 4),
         {:ok, time} <- Time.from_iso8601(raw_time),
         {:ok, eastern_time} <-
           DateTime.shift_zone(current_time, "America/New_York"),
         {:ok, timestamp} <-
           DateTime.new(DateTime.to_date(eastern_time), time, "America/New_York") do
      {:ok, timestamp}
    else
      error -> {:error, error}
    end
  end
end
