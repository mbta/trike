defmodule Trike.CloudEvent do
  @moduledoc """
  Represents a standard CloudEvent as well as a function for creating new
  CloudEvents from OCS messages.
  """
  alias Trike.OcsRawMessage

  require Logger

  @type t() :: %__MODULE__{
          specversion: String.t(),
          type: String.t(),
          source: String.t(),
          id: String.t(),
          partitionkey: String.t(),
          time: DateTime.t(),
          data: any(),
          sourceip: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:specversion, :type, :id, :partitionkey, :sourceip, :time, :data]
  defstruct @enforce_keys ++
              [
                source: "#{:inet.gethostname() |> elem(1)}.mbta.com/trike"
              ]

  @doc """
  Creates one or more CloudEvent structs given a full OCS message, the current time, a partition key, and the source IP.
  For each OCS message, at minimum we create a raw event that contains the original payload.
  We may also create one or more additional parsed events, depending on that message type's manifest.
  """
  @spec from_ocs_message(binary(), DateTime.t(), String.t(), String.t()) :: list(t())
  def from_ocs_message(message, current_time, partition_key, source_ip) do
    raw_event = %__MODULE__{
      specversion: "1.0",
      type: "com.mbta.ocs.raw_message",
      id: :crypto.hash(:sha, [DateTime.to_iso8601(current_time), message]) |> Base.encode64(),
      partitionkey: partition_key,
      sourceip: source_ip,
      time: current_time,
      data: %OcsRawMessage{raw: message}
    }

    parsed_events =
      case OCS.Parser.parse(message, current_time) do
        {:ok, parsed_message} ->
          from_parsed_ocs(parsed_message, message, current_time, partition_key, source_ip)

        # Ignore unimplemented message types
        {:error, %OCS.Parser.UnimplementedMessageTypeError{}} ->
          []

        {:error, e} ->
          Logger.warning("ocs_parse_error raw=#{message} error=#{Exception.format(:error, e)}")
      end

    [raw_event | parsed_events]
  end

  @spec from_parsed_ocs(OCS.Message.t(), binary(), DateTime.t(), String.t(), String.t()) ::
          list(t())
  defp from_parsed_ocs(parsed_message, raw_message, current_time, partition_key, source_ip) do
    Trike.CloudEvent.Manifest.manifest_from_ocs(parsed_message)
    |> Enum.map(fn {type, specversion, data} ->
      id =
        :crypto.hash(:sha, [
          DateTime.to_iso8601(current_time),
          raw_message,
          type,
          specversion
        ])
        |> Base.encode64()

      %Trike.CloudEvent{
        specversion: specversion,
        type: type,
        id: id,
        partitionkey: partition_key,
        sourceip: source_ip,
        time: current_time,
        data: data
      }
    end)
  end
end
