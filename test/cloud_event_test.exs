defmodule CloudEventTest do
  use ExUnit.Case
  alias Trike.CloudEvent

  test "creates an event from an OCS message" do
    now = Fakes.FakeDateTime.utc_now()

    assert CloudEvent.from_ocs_message("4994,TSCH,02:00:06,R,RLD,W", now, "1bQ0GxT4mk") ==
             %CloudEvent{
               data: %Trike.OcsRawMessage{
                 raw: "4994,TSCH,02:00:06,R,RLD,W",
                 received_time: ~U[2021-08-13 12:00:00Z]
               },
               id:
                 "MKHkLK0QpFSsMkz8MeIw1UvgnAY2iGPTCLY+U1y4M8UVHNFTz+21I6TRrllJBAmyK3Jn3K8kwVxL3owWUFJX2g==",
               partitionkey: "1bQ0GxT4mk",
               source: "opstech3.mbta.com/trike",
               specversion: "1.0",
               time: DateTime.new!(~D[2021-08-13], ~T[02:00:06], "America/New_York"),
               type: "com.mbta.ocs.raw_message"
             }
  end
end
