defmodule Fakes.FakeKinesisClient do
  @moduledoc """
  A fake Kinesis client that logs records to the console.
  """
  require Logger

  @spec put_record(ExAws.Kinesis.stream_name(), binary(), binary()) :: :ok
  def put_record(stream, partition_key, data) do
    Logger.info([
      "Sending event to ",
      stream,
      "\nPartitionKey: ",
      partition_key,
      "\nData: ",
      inspect(Jason.decode!(data), pretty: true)
    ])
  end
end
