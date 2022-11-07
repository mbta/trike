defmodule ProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Fakes.FakeDateTime
  alias Trike.Proxy

  @eot <<4>>

  test "sends a properly formatted event to Kinesis" do
    state = %{
      buffer: "",
      partition_key: "test_key",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data ->
        send(self(), {:put_record, stream, key, data})
        {:ok, :ok}
      end,
      socket: :socket,
      transport: __MODULE__.FakeTransport,
      received: 0
    }

    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}"

    Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"}])

    assert_received({:put_record, "test_stream", "test_key", ^event})
    assert_received({:setopts, :socket, active: :once})
  end

  test "combines multiple OCS records into a single Kinesis batched record" do
    state = %{
      buffer: "",
      partition_key: "test_key",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data ->
        send(self(), {:put_record, stream, key, data})
        {:ok, :ok}
      end,
      socket: :socket,
      transport: __MODULE__.FakeTransport,
      received: 0
    }

    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}4995,TSCH,03:00:06,R,RLD,W#{@eot}"

    Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"},{\"data\":{\"raw\":\"4995,TSCH,03:00:06,R,RLD,W\"},\"id\":\"O7ODUPlPMM089UZL1YLYpFIZzeo=\",\"partitionkey\":\"test_key\",\"source\":\"opstech3.mbta.com/trike\",\"specversion\":\"1.0\",\"time\":\"2021-08-13T12:00:00Z\",\"type\":\"com.mbta.ocs.raw_message\"}])

    assert_received({:put_record, "test_stream", "test_key", ^event})
    assert_received({:setopts, :socket, active: :once})
  end

  test "builds events with buffer" do
    state = %{
      buffer: "4994,TSCH,02:00:06",
      partition_key: "test_key",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data ->
        send(self(), {:put_record, stream, key, data})
        {:ok, :ok}
      end,
      socket: :socket,
      transport: __MODULE__.FakeTransport,
      received: 0
    }

    data = ",R,RLD,W#{@eot}4995,TSCH,02:00:07"
    rest = "4995,TSCH,02:00:07"

    {:noreply, %{buffer: buffer}} = Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"}])

    assert_received({:put_record, "test_stream", "test_key", ^event})

    assert buffer == rest
  end

  test "starts health checker after connecting" do
    log =
      capture_log(fn ->
        {:ok, _socket} = :gen_tcp.connect(:localhost, 8001, [])
        Process.sleep(200)
      end)

    assert log =~ "Started health checker"
  end

  test "logs connection string on shutdown" do
    connection_string = "1.2.3.4:5 -> 6.7.8.9:10"

    shutdown_log =
      capture_log(fn ->
        Proxy.handle_info({:tcp_closed, "socket"}, %{partition_key: connection_string})
      end)

    assert shutdown_log =~ "Socket closed: #{inspect(connection_string)}"
  end

  defmodule FakeTransport do
    @spec setopts(any(), Keyword.t()) :: :ok
    def setopts(socket, opts) when is_list(opts) do
      send(self(), {:setopts, socket, opts})
    end
  end
end
