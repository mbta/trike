defmodule Mix.Tasks.FakeSource do
  use Mix.Task
  require Logger

  @eot <<4>>

  @doc """
  Ex: mix fake_source --port 8001
  """
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [port: :integer])
    port = opts[:port]
    host = {127, 0, 0, 1}
    {:ok, sock} = do_connect(host, port)
    do_send(sock, host, port)
  end

  def do_connect(host, port) do
    case :gen_tcp.connect(host, port, [:binary, active: false, send_timeout: 1000]) do
      {:ok, sock} ->
        {:ok, sock}

      {:error, err} ->
        Logger.info("Couldn't connect: #{err}, trying again shortly")
        :timer.sleep(2_000)
        do_connect(host, port)
    end
  end

  def do_send(sock, host, port) do
    "priv/ocs_data.csv"
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.take_while(&(:ok == :gen_tcp.send(sock, [&1, @eot])))
    |> Enum.each(&Logger.info("Sent #{inspect(&1)}"))

    Logger.error("Err: could not send message")
    :gen_tcp.close(sock)
    {:ok, sock} = do_connect(host, port)
    do_send(sock, host, port)
  end
end
