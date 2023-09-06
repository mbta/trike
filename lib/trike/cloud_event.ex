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
  Creates a CloudEvent struct given a full OCS message, the current time, and a partition key.
  """
  @spec from_ocs_message(binary(), DateTime.t(), String.t()) :: t()
  def from_ocs_message(message, current_time, partition_key) do
    %__MODULE__{
      id: :crypto.hash(:sha, [DateTime.to_iso8601(current_time), message]) |> Base.encode64(),
      partitionkey: partition_key,
      time: current_time,
      data: %OcsRawMessage{raw: message}
    }
  end
end
