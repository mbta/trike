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
        :timer.sleep(500)
      end)

      :gen_tcp.close(socket)

  end
end
