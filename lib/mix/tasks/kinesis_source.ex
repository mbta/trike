defmodule Mix.Tasks.KinesisSource do
  @moduledoc """

  A source of OCS messages that reads in a Kinesis stream of OCS messages and
  sends them to Trike on the specified port (8001 by default).

  """
  use Mix.Task
  require Logger

  @doc """
  Ex: mix kinesis_source <stream name> --port 8001
  """
  @impl true
  def run(args) do
    {opts, [stream_name], _unknowns} =
      OptionParser.parse(args,
        strict: [
          host: :string,
          port: :integer,
          shard_iterator_type: :string,
          frequency: :integer,
          scale: :integer
        ]
      )

    host =
      if opts[:host] do
        String.to_charlist(opts[:host])
      else
        '127.0.0.1'
      end

    port = opts[:port] || 8001

    shard_iterator_type =
      case opts[:shard_iterator_type] do
        nil -> :latest
        "LATEST" -> :latest
        "TRIM_HORIZON" -> :trim_horizon
      end

    frequency = opts[:frequency] || 1_000
    scale = opts[:scale] || 1

    Application.ensure_all_started(:hackney)
    Application.ensure_all_started(:ex_aws)

    %{"StreamDescription" => %{"Shards" => shards}} =
      stream_name
      |> ExAws.Kinesis.describe_stream()
      |> ExAws.request!()

    for %{"ShardId" => shard_id} <- shards do
      {:ok, _} =
        GenServer.start_link(__MODULE__.ShardToPort,
          stream_name: stream_name,
          shard_id: shard_id,
          shard_iterator_type: shard_iterator_type,
          host: host,
          port: port,
          frequency: frequency,
          scale: scale
        )
    end

    receive do
      :not_received -> :ok
    end
  end

  defmodule ShardToPort do
    @moduledoc """

    GenServer which follows a Kinesis stream, forwarding the messages to a Trike
    instance over TCP.

    """
    use GenServer

    @eot <<4>>

    @impl GenServer
    def init(args) do
      shard_iterator =
        get_shard_iterator(args[:stream_name], args[:shard_id], args[:shard_iterator_type])

      state = %{
        shard_id: args[:shard_id],
        host: args[:host],
        port: args[:port],
        sock: nil,
        shard_iterator: shard_iterator,
        scale: args[:scale],
        frequency: args[:frequency]
      }

      {:ok, sock} = do_connect(state)

      state = %{state | sock: sock}

      send(self(), :timeout)

      {:ok, state}
    end

    @impl GenServer
    def handle_info(:timeout, state) do
      start = now()

      {shard_iterator, records} = get_records(state)

      state = maybe_send(state, shard_iterator, records)

      Process.send_after(self(), :timeout, start + state.frequency, abs: true)
      {:noreply, state}
    end

    defp now do
      System.monotonic_time(:millisecond)
    end

    defp maybe_send(state, shard_iterator, records)

    defp maybe_send(state, _, []) do
      state
    end

    defp maybe_send(state, shard_iterator, records) do
      decoded_messages =
        for %{"Data" => b64_data} <- records do
          b64_data
          |> Base.decode64!()
          |> Jason.decode!()
        end

      raw_messages =
        for record <- decoded_messages do
          record
          |> Map.fetch!("data")
          |> Map.fetch!("raw")
        end

      scaled_messages = Enum.flat_map(raw_messages, &List.duplicate(&1, state.scale))

      case :gen_tcp.send(state.sock, [Enum.intersperse(scaled_messages, @eot), @eot]) do
        :ok ->
          latest =
            decoded_messages
            |> Enum.at(-1, %{"time" => :unknown})
            |> Map.fetch!("time")

          Logger.info(
            "shard_id=#{state.shard_id} Forwarded messages, count=#{length(scaled_messages)} latest=#{latest}"
          )

          %{state | shard_iterator: shard_iterator}

        {:error, e} ->
          Logger.error("shard_id=#{state.shard_id} Error sending messages: #{inspect(e)}")
          :gen_tcp.close(state.sock)
          {:ok, sock} = do_connect(state)
          # don't update the shard iterator, so we re-fetch those messages
          %{state | sock: sock}
      end
    end

    @spec get_shard_iterator(String.t(), String.t(), atom) :: String.t()
    defp get_shard_iterator(stream_name, shard_id, shard_iterator_type) do
      %{"ShardIterator" => shard_iterator} =
        stream_name
        |> ExAws.Kinesis.get_shard_iterator(shard_id, shard_iterator_type)
        |> ExAws.request!()

      shard_iterator
    end

    defp get_records(state) do
      %{
        "NextShardIterator" => next_iterator,
        "Records" => records,
        "MillisBehindLatest" => ms_behind_latest
      } =
        state.shard_iterator
        |> ExAws.Kinesis.get_records()
        |> ExAws.request!()

      Logger.info(
        "shard_id=#{state.shard_id} Received records count=#{length(records)} ms_behind_latest=#{ms_behind_latest}"
      )

      {next_iterator, records}
    end

    defp do_connect(state) do
      case :gen_tcp.connect(state.host, state.port, [:binary, active: false, send_timeout: 1_000]) do
        {:ok, sock} ->
          Logger.info("shard_id=#{state.shard_id} Connected to #{state.host}:#{state.port}!")
          {:ok, sock}

        {:error, err} ->
          Logger.info(
            "shard_id=#{state.shard_id}  Couldn't connect to #{state.host}:#{state.port}: #{err}, trying again shortly"
          )

          :timer.sleep(2_000)
          do_connect(state)
      end
    end
  end
end
