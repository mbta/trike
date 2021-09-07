import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ex_aws, json_codec: Jason

config :trike,
  listen_port: System.get_env("LISTEN_PORT", "8001") |> String.to_integer(),
  kinesis_stream: System.get_env("KINESIS_STREAM", "console"),
  kinesis_client: Fakes.FakeKinesisClient,
  clock: DateTime

if config_env() == :test do
  config :trike, clock: Fakes.FakeDateTime
end

if config_env() == :prod do
  config :trike,
    listen_port: System.get_env("LISTEN_PORT") |> String.to_integer(),
    kinesis_stream: System.get_env("KINESIS_STREAM"),
    kinesis_client: ExAws.Kinesis

  config :logger, backends: [Logger.Backend.Splunk, :console]

  config :logger, Logger.Backend.Splunk,
    host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
    token: System.get_env("TRIKE_SPLUNK_TOKEN"),
    format: "$dateT$time $metadata[$level] node=$node $message\n",
    level: :info

  config :logger, :console, level: :warn
end
