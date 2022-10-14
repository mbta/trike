defmodule HealthCheckerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Trike.HealthChecker

  test "health check logs required info" do
    conn_str = "1.2.3.4:5 -> 6.7.8.9:10"

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

    health_check_log =
      capture_log(fn ->
        HealthChecker.handle_info(
          :check_health,
          %{ranch_ref: ranch_ref, proxy_pid: self(), connection_string: conn_str}
        )
      end)

    assert health_check_log =~
             "Proxy \"1.2.3.4:5 -> 6.7.8.9:10\" mailbox size: 0 ranch.info: %{active_connections: "
  end
end
