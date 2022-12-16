defmodule ProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Fakes.FakeDateTime
  alias Trike.Proxy

  @eot <<4>>

  setup do
    state = %Proxy{
      buffer: "",
      partition_key: "test_key",
      clock: FakeDateTime,
      stream: "test_stream",
      put_record_fn: fn stream, key, data, opts ->
        send(self(), {:put_record, stream, key, data, opts})
        {:ok, %{"SequenceNumber" => "0"}}
      end,
      socket: :socket,
      transport: __MODULE__.FakeTransport
    }

    {:ok, %{state: state}}
  end

  test "sends a properly formatted event to Kinesis", %{state: state} do
    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}"

    Proxy.handle_info({:tcp, state.socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"}])

    assert_received({:put_record, "test_stream", "test_key", ^event, []})
    assert_received({:setopts, :socket, active: :once})
  end

  test "combines multiple OCS records into a single Kinesis batched record", %{state: state} do
    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}4995,TSCH,03:00:06,R,RLD,W#{@eot}"

    Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"},{\"data\":{\"raw\":\"4995,TSCH,03:00:06,R,RLD,W\"},\"id\":\"O7ODUPlPMM089UZL1YLYpFIZzeo=\",\"partitionkey\":\"test_key\",\"source\":\"opstech3.mbta.com/trike\",\"specversion\":\"1.0\",\"time\":\"2021-08-13T12:00:00Z\",\"type\":\"com.mbta.ocs.raw_message\"}])

    assert_received({:put_record, "test_stream", "test_key", ^event, []})
    assert_received({:setopts, :socket, active: :once})
  end

  test "does not send a record if we didn't receive a full packet", %{state: state} do
    state = %{state | buffer: "buffer"}
    data = "partial"

    {:noreply, new_state} = Proxy.handle_info({:tcp, :socket, data}, state)

    expected_state = %{state | buffer: "bufferpartial"}
    assert expected_state == new_state

    refute_received({:put_record, _stream, _key, _event, _opts})
    assert_received({:setopts, :socket, active: :once})
  end

  test "builds events with buffer", %{state: state} do
    state = %{state | buffer: "4994,TSCH,02:00:06"}
    data = ",R,RLD,W#{@eot}4995,TSCH,02:00:07"
    rest = "4995,TSCH,02:00:07"

    {:noreply, %{buffer: buffer}} = Proxy.handle_info({:tcp, :socket, data}, state)

    event =
      ~s([{"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W"},"id":"myH7tTFo1tuZdSXxQ/5QFA4Xx58=","partitionkey":"test_key","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T12:00:00Z","type":"com.mbta.ocs.raw_message"}])

    assert_received({:put_record, "test_stream", "test_key", ^event, []})

    assert buffer == rest
  end

  test "sends the previous sequence number to ensure ordering", %{state: state} do
    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}"

    {:noreply, state} = Proxy.handle_info({:tcp, state.socket, data}, state)
    {:noreply, _state} = Proxy.handle_info({:tcp, state.socket, data}, state)

    assert_received({:put_record, "test_stream", "test_key", _event, []})

    assert_received(
      {:put_record, "test_stream", "test_key", _event, [sequence_number_for_ordering: "0"]}
    )

    assert_received({:setopts, :socket, active: :once})
  end

  test "logs connection string on shutdown", %{state: state} do
    connection_string = "1.2.3.4:5 -> 6.7.8.9:10"

    shutdown_log =
      capture_log(fn ->
        Proxy.handle_info({:tcp_closed, state.socket}, %{state | partition_key: connection_string})
      end)

    assert shutdown_log =~ "Socket closed"
    assert shutdown_log =~ inspect(connection_string)
  end

  defmodule FakeTransport do
    @spec setopts(any(), Keyword.t()) :: :ok
    def setopts(socket, opts) when is_list(opts) do
      send(self(), {:setopts, socket, opts})
    end
  end

  test "logs messages", %{state: state} do
    data = "4994,TSCH,02:00:06,R,RLD,W#{@eot}4995,TSCH,03:00:06,R,RLD,W#{@eot}"

    proxy_log = capture_log(fn -> Proxy.handle_info({:tcp, state.socket, data}, state) end)

    assert proxy_log =~ "ocs_event raw=\"4994"
    assert proxy_log =~ "ocs_event raw=\"4995"
  end
end
