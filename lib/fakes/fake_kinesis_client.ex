defmodule Fakes.FakeKinesisClient do
  @moduledoc """
  A Kinesis client that logs records to the console.
  """
  require Logger

  @spec put_record(ExAws.Kinesis.stream_name(), binary(), binary(), Keyword.t()) ::
          {:ok, %{String.t() => String.t()}}
  def put_record(stream, partition_key, data, _opts \\ []) do
    Logger.info([stream, "\n", partition_key, "\n", data])
    {:ok, %{"SequenceNumber" => "0"}}
  end
end
