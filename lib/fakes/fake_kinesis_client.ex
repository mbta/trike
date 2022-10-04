defmodule Fakes.FakeKinesisClient do
  @moduledoc """
  A Kinesis client that logs records to the console.
  """
  require Logger

  @send_delay Application.compile_env(:trike, :send_delay)

  @spec put_record(ExAws.Kinesis.stream_name(), binary(), binary()) :: {:ok, :ok}
  def put_record(stream, partition_key, data) do
    Process.sleep(@send_delay)
    Logger.info([stream, "\n", partition_key, "\n", data])
    {:ok, :ok}
  end
end
