defmodule Mix.Tasks.FakeSource do
  @moduledoc """
  A fake source of OCS messages that reads in canned messages from
  priv/ocs_data.csv and sends them to Trike on the specified port (8001 by
  default). Also sends bad data if you ask it to.
  """
  use Mix.Task
  require Logger

  @eot <<4>>

  @doc """
  Ex: mix fake_source --port 8001
  """
  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [{:port, :integer}, host: :string, bad: :boolean, good: :boolean]
      )

    port = opts[:port] || 8001
    bad = opts[:bad]
    good = opts[:good]
    host = String.to_charlist(opts[:host] || "localhost")
    {:ok, sock} = do_connect(host, port)
    do_send(sock, host, port, good, bad)
  end

  @spec do_connect(:inet.hostname(), :inet.port_number()) :: {:ok, :gen_tcp.socket()}
  defp do_connect(host, port) do
    case :gen_tcp.connect(host, port, [:binary, active: false, send_timeout: 1_000]) do
      {:ok, sock} ->
        {:ok, sock}

      {:error, err} ->
        Logger.info("Couldn't connect to #{host}:#{port}: #{err}, trying again shortly")
        :timer.sleep(2_000)
        do_connect(host, port)
    end
  end

  @spec do_send(
          :gen_tcp.socket(),
          :inet.hostname(),
          :inet.port_number(),
          boolean(),
          boolean()
        ) ::
          no_return()
  defp do_send(sock, host, port, send_good, send_bad) do
    "priv/ocs_data.csv"
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.take_while(fn line ->
      :timer.sleep(1_000)
      fail = rem(Time.utc_now().second, 5) == 0
      bytes = :crypto.strong_rand_bytes(5)

      cond do
        send_good && send_bad && fail ->
          Logger.info("Sending bad message #{inspect(bytes)}")
          log_if_not_ok(:gen_tcp.send(sock, [bytes, @eot]))

        send_good ->
          Logger.info("Sending #{line}")
          log_if_not_ok(:gen_tcp.send(sock, [line, @eot]))

        send_bad ->
          Logger.info("Sending bad message #{inspect(bytes)}")
          log_if_not_ok(:gen_tcp.send(sock, [bytes, @eot]))
      end
    end)
    |> Stream.run()

    :gen_tcp.close(sock)
    {:ok, sock} = do_connect(host, port)
    do_send(sock, host, port, send_good, send_bad)
  end

  defp log_if_not_ok(:ok) do
    true
  end

  defp log_if_not_ok(error) do
    Logger.error("Err: could not send message: #{inspect(error)}")
    false
  end
end
