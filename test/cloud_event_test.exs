defmodule CloudEventTest do
  use ExUnit.Case
  alias Trike.CloudEvent

  test "creates an event from an OCS message" do
    now = Fakes.FakeDateTime.utc_now()

    assert CloudEvent.from_ocs_message("4994,TSCH,02:00:06,R,RLD,W", now, "1bQ0GxT4mk") ==
             {:ok,
              %CloudEvent{
                data: %Trike.OcsRawMessage{
                  raw: "4994,TSCH,02:00:06,R,RLD,W",
                  received_time: ~U[2021-08-13 12:00:00Z]
                },
                id: "gVACBi3Es6Afha8Ik7SQP1lx3Jk=",
                partitionkey: "1bQ0GxT4mk",
                source: "opstech3.mbta.com/trike",
                specversion: "1.0",
                time: DateTime.new!(~D[2021-08-13], ~T[02:00:06], "America/New_York"),
                type: "com.mbta.ocs.raw_message"
              }}
  end

  test "returns an error when parsing fails" do
    bad = :crypto.strong_rand_bytes(10)
    assert {:error, _} = CloudEvent.from_ocs_message(bad, DateTime.utc_now(), "foo")
  end
end
