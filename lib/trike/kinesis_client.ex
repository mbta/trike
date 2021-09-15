defmodule Trike.KinesisClient do
  @moduledoc """
  Functions for interacting with AWS Kinesis.
  """
  alias ExAws.Kinesis

  @doc """
  Puts a new record in the provided AWS Kinesis Data Stream with the given
  partition key.
  """
  @spec put_record(Kinesis.stream_name(), binary(), binary()) :: {:ok, term()} | {:error, term()}
  def put_record(stream, partition_key, event) do
    ExAws.request(Kinesis.put_record(stream, partition_key, event))
  end
end
