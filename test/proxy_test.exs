defmodule ProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  @eot <<4>>

  test "sends a properly formatted event to Kinesis" do
    {:ok, socket} = :gen_tcp.connect(:localhost, 8001, [])
    {:ok, port} = :inet.port(socket)

    log =
      capture_log(fn ->
        :gen_tcp.send(socket, ["4994,TSCH,02:00:06,R,RLD,W", @eot])
        :timer.sleep(200)
      end)

    assert log =~
             """
             console
             {127.0.0.1:8001 -> 127.0.0.1:#{port}}
             {"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W","received_time":"2021-08-13T12:00:00Z"},"id":"MKHkLK0QpFSsMkz8MeIw1UvgnAY2iGPTCLY+U1y4M8UVHNFTz+21I6TRrllJBAmyK3Jn3K8kwVxL3owWUFJX2g==","partitionkey":"{127.0.0.1:8001 -> 127.0.0.1:#{port}}","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T02:00:06-04:00","type":"com.mbta.ocs.raw_message"}
             """
  end

  test "builds events from multiple packets" do
    {:ok, socket} = :gen_tcp.connect(:localhost, 8001, [])
    {:ok, port} = :inet.port(socket)

    log =
      capture_log(fn ->
        :gen_tcp.send(socket, "4994,TSCH,02:00:06")
        :gen_tcp.send(socket, [",R,RLD,W", @eot, "4995,TSCH,02:00:06"])
        :gen_tcp.send(socket, [",R,RLD,W", @eot])
        :timer.sleep(200)
      end)

      assert log =~
      """
      console
      {127.0.0.1:8001 -> 127.0.0.1:#{port}}
      {"data":{"raw":"4994,TSCH,02:00:06,R,RLD,W","received_time":"2021-08-13T12:00:00Z"},"id":"MKHkLK0QpFSsMkz8MeIw1UvgnAY2iGPTCLY+U1y4M8UVHNFTz+21I6TRrllJBAmyK3Jn3K8kwVxL3owWUFJX2g==","partitionkey":"{127.0.0.1:8001 -> 127.0.0.1:#{port}}","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T02:00:06-04:00","type":"com.mbta.ocs.raw_message"}
      """

      assert log =~
      """
      console
      {127.0.0.1:8001 -> 127.0.0.1:#{port}}
      {"data":{"raw":"4995,TSCH,02:00:06,R,RLD,W","received_time":"2021-08-13T12:00:00Z"},"id":"USj9TixGA6R42TCmu0raEptXPYwEyXTbybn3bOaFhwKnsnMqXK2alX+NQj5v4JZ6I1UE7xwsY1qd/fv/wgwGpg==","partitionkey":"{127.0.0.1:8001 -> 127.0.0.1:#{port}}","source":"opstech3.mbta.com/trike","specversion":"1.0","time":"2021-08-13T02:00:06-04:00","type":"com.mbta.ocs.raw_message"}
      """
  end
end
