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
      OptionParser.parse(args, strict: [host: :string, port: :integer])

    host =
      if opts[:host] do
        String.to_charlist(opts[:host])
      else
        '127.0.0.1'
      end

    port = opts[:port] || 8001
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
          host: host,
          port: port
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
      {:ok, sock} = do_connect(args[:host], args[:port])
      shard_iterator = get_shard_iterator(args[:stream_name], args[:shard_id], :latest)
      send(self(), :timeout)

      state = %{
        sock: sock,
        shard_iterator: shard_iterator
      }

      {:ok, state}
    end

    @impl GenServer
    def handle_info(:timeout, state) do
      {shard_iterator, records} = get_records(state.shard_iterator)

      decoded_messages =
        for %{"Data" => b64_data} <- records do
          b64_data
          |> Base.decode64!()
          |> Jason.decode!()
          |> Map.fetch!("data")
          |> Map.fetch!("raw")
        end

      :ok = :gen_tcp.send(state.sock, [Enum.intersperse(decoded_messages, @eot), @eot])
      Logger.info("Forwarded #{length(decoded_messages)} messages")
      state = %{state | shard_iterator: shard_iterator}

      {:noreply, state, 1_000}
    end

    @spec get_shard_iterator(String.t(), String.t(), :latest) :: String.t()
    defp get_shard_iterator(stream_name, shard_id, shard_iterator_type) do
      %{"ShardIterator" => shard_iterator} =
        stream_name
        |> ExAws.Kinesis.get_shard_iterator(shard_id, shard_iterator_type)
        |> ExAws.request!()

      shard_iterator
    end

    @spec get_records(String.t()) :: {String.t(), [map]}
    defp get_records(shard_iterator) do
      %{"NextShardIterator" => next_iterator, "Records" => records} =
        shard_iterator
        |> ExAws.Kinesis.get_records()
        |> ExAws.request!()

      {next_iterator, records}
    end

    @spec do_connect(:inet.hostname(), :inet.port_number()) :: {:ok, :gen_tcp.socket()}
    defp do_connect(host, port) do
      case :gen_tcp.connect(host, port, [:binary, active: false, send_timeout: 1_000]) do
        {:ok, sock} ->
          Logger.info("Connected to #{host}:#{port}!")
          {:ok, sock}

        {:error, err} ->
          Logger.info("Couldn't connect to #{host}:#{port}: #{err}, trying again shortly")
          :timer.sleep(2_000)
          do_connect(host, port)
      end
    end
  end
end
