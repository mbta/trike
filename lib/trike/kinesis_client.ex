defmodule Trike.KinesisClient do
  @moduledoc """
  Functions for interacting with AWS Kinesis.
  """
  alias ExAws.Kinesis

  @doc """
  Puts a new record in the provided AWS Kinesis Data Stream with the given
  partition key.
  """
  @spec put_record(Kinesis.stream_name(), binary(), binary(), Keyword.t()) ::
          {:ok, %{String.t() => String.t()}} | {:error, term()}
  def put_record(stream, partition_key, event, opts \\ []) do
    ExAws.request(Kinesis.put_record(stream, partition_key, event, opts))
  end
end
