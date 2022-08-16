import Config

kinesis_stream = System.get_env("KINESIS_STREAM", "console")
splunk_token = System.get_env("TRIKE_SPLUNK_TOKEN", "")

config :trike,
  listen_port: System.get_env("LISTEN_PORT", "8001") |> String.to_integer(),
  kinesis_stream: kinesis_stream

if config_env() == :prod and splunk_token != "" do
  config :logger, backends: [Logger.Backend.Splunk, :console]

  config :logger, Logger.Backend.Splunk,
    host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
    format: "$dateT$time $metadata[$level] node=$node $message\n",
    level: :info,
    token: splunk_token
end

if kinesis_stream == "console" do
  # use fake client if logging to the console
  config :trike,
    kinesis_client: Fakes.FakeKinesisClient
end
