defmodule Fakes.PersistentKinesisClient do
  @moduledoc """
  A Kinesis client that saves records to internal state.
  """
  use GenServer
  require Logger

  @type records() :: list({ExAws.Kinesis.stream_name(), binary(), binary()})
  @type t() :: %__MODULE__{
          records: records()
        }

  defstruct records: []

  def start(port: port) do
    GenServer.start(__MODULE__, [], name: String.to_atom("{127.0.0.1:8001 -> 127.0.0.1:#{port}}"))
  end

  @spec put_record(ExAws.Kinesis.stream_name(), binary(), binary()) :: :ok
  def put_record(stream, partition_key, data) do
    GenServer.call(String.to_atom(partition_key), {:put_record, stream, partition_key, data})
  end

  @spec get_records(pid()) :: records()
  def get_records(pid) do
    GenServer.call(pid, :get_records)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(
        {:put_record, stream_name, partition_key, data},
        _from,
        %{records: records} = state
      ) do
    {:noreply, %{state | records: [{stream_name, partition_key, data} | records]}}
  end

  @impl true
  def handle_call(:get_records, _from, %{records: records} = state) do
    {:reply, records, state}
  end
end
