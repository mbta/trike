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
end
