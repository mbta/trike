import Config

config :trike,
  clock: Fakes.FakeDateTime,
  staleness_check_interval_ms: 3_000
