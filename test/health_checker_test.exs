defmodule HealthCheckerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Trike.HealthChecker

  test "health check logs required info" do
    ranch_ref = make_ref()

    :ranch.start_listener(
      ranch_ref,
      :ranch_tcp,
      [{:port, 8002}],
      Trike.Proxy,
      stream: nil,
      kinesis_client: Application.get_env(:trike, :kinesis_client),
      clock: Application.get_env(:trike, :clock)
    )

    {:ok, _socket} = :gen_tcp.connect(:localhost, 8002, [])

    health_check_log =
      capture_log(fn ->
        HealthChecker.log_ranch_info(ranch_ref)
      end)

    assert health_check_log =~ "ranch_info=%{active_connections: "
    assert health_check_log =~ "Proxy proxy_pid=#PID<"
    assert health_check_log =~ ~s[conn="{127.0.0.1:8002 -> ]
    assert health_check_log =~ "mailbox_size="
  end
end
