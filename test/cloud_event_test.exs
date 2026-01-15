defmodule CloudEventTest do
  use ExUnit.Case
  alias Trike.CloudEvent

  test "creates an event from an OCS message" do
    now = Fakes.FakeDateTime.utc_now()

    expected_raw = %CloudEvent{
      data: %Trike.OcsRawMessage{raw: "4994,TSCH,02:00:06,R,RLD,W"},
      id: "myH7tTFo1tuZdSXxQ/5QFA4Xx58=",
      sourceip: "127.0.0.1",
      partitionkey: "1bQ0GxT4mk",
      source: "#{:inet.gethostname() |> elem(1)}.mbta.com/trike",
      specversion: "1.0",
      time: ~U[2021-08-13 12:00:00Z],
      type: "com.mbta.ocs.raw_message"
    }

    expected_parsed = %CloudEvent{
      data: %Trike.CloudEvent.TschRldV1{
        counter: 4994,
        timestamp: ~U[2021-08-13 02:00:06Z],
        transitLine: "R"
      },
      id: "PI/tYKeSbj90St8HD7dre2b8sHg=",
      sourceip: "127.0.0.1",
      partitionkey: "1bQ0GxT4mk",
      source: "#{:inet.gethostname() |> elem(1)}.mbta.com/trike",
      specversion: "1.0",
      time: ~U[2021-08-13 12:00:00Z],
      type: "com.mbta.ocs.tsch_rld.v1"
    }

    result =
      CloudEvent.from_ocs_message(
        "4994,TSCH,02:00:06,R,RLD,W",
        now,
        "1bQ0GxT4mk",
        "127.0.0.1"
      )

    assert result == [expected_raw, expected_parsed]
  end
end
