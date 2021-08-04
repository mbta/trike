import Config

config :trike,
  listen_port: System.get_env("LISTEN_PORT"),
  kinesis_stream: System.get_env("KINESIS_STREAM")

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ex_aws, json_codec: Jason

if config_env() == :prod do
  config :trike, kinesis_client: ExAws.Kinesis
end

if config_env() == :dev do
  config :trike, kinesis_client: Fakes.FakeKinesisClient
end
