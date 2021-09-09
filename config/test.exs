import Config

config :trike,
  kinesis_client: Fakes.PersistentKinesisClient,
  clock: Fakes.FakeDateTime,
  staleness_check_interval_ms: 3_000
