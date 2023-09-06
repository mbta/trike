defmodule CloudEventTest do
  use ExUnit.Case
  alias Trike.CloudEvent

  test "creates an event from an OCS message" do
    now = Fakes.FakeDateTime.utc_now()

    assert CloudEvent.from_ocs_message(
             "4994,TSCH,02:00:06,R,RLD,W",
             now,
             "1bQ0GxT4mk",
             "127.0.0.1"
           ) ==
             %CloudEvent{
               data: %Trike.OcsRawMessage{raw: "4994,TSCH,02:00:06,R,RLD,W"},
               id: "myH7tTFo1tuZdSXxQ/5QFA4Xx58=",
               sourceip: "127.0.0.1",
               partitionkey: "1bQ0GxT4mk",
               source: "#{:inet.gethostname() |> elem(1)}.mbta.com/trike",
               specversion: "1.0",
               time: ~U[2021-08-13 12:00:00Z],
               type: "com.mbta.ocs.raw_message"
             }
  end
end
