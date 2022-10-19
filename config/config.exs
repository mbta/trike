import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ex_aws, json_codec: Jason

config :trike,
  kinesis_client: Fakes.FakeKinesisClient,
  clock: DateTime,
  health_check_interval_ms: 30 * 60 * 1_000 

import_config "#{config_env()}.exs"
