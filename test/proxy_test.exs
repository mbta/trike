defmodule ProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Fakes.FakeDateTime
  alias Trike.Proxy

  @eot <<4>>

  test "sends a properly formatted event to Kinesis" do
    state = %{
      buffer: "",
      connection_string: "{us -> them}",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data ->
        send(self(), {:put_record, stream, key, data})
        {:ok, :ok}
      end,
      received: 0
    }

    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}"

    Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s({"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"{us -> them}","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"})

    assert_received({:put_record, "test_stream", "{us -> them}", ^event})
  end

  test "builds events with buffer" do
    state = %{
      buffer: "4994,TSCH,02:00:06",
      connection_string: "{us -> them}",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data ->
        send(self(), {:put_record, stream, key, data})
        {:ok, :ok}
      end,
      received: 0
    }

    data = ",R,RLD,W#{@eot}4995,TSCH,02:00:07"
    rest = "4995,TSCH,02:00:07"

    {:noreply, %{buffer: buffer}} = Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s({"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"{us -> them}","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"})

    assert_received({:put_record, "test_stream", "{us -> them}", ^event})

    assert buffer == rest
  end

  test "logs staleness check" do
    staleness_check = capture_log(fn -> Proxy.handle_info(:staleness_check, %{received: 9}) end)

    assert staleness_check =~ "Stale Proxy pid=#{inspect(self())}, received=9"
  end

  test "logs connection string when the TCP socket is closed" do
    tcp_closed =
      capture_log(fn ->
        Proxy.handle_info({:tcp_closed, :socket}, %{connection_string: "{us <- them}"})
      end)

    assert tcp_closed =~ "{us <- them}"
  end
end
