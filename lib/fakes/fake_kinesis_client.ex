defmodule Fakes.FakeKinesisClient do
  @moduledoc """
  A Kinesis client that logs records to the console.
  """
  require Logger

   @spec put_record(ExAws.Kinesis.stream_name(), binary(), binary()) :: {:ok, :ok}
  def put_record(stream, partition_key, data) do
    Logger.info([stream, "\n", partition_key, "\n", data])
    {:ok, :ok}
  end
end
