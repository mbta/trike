import Config

config :trike,
  clock: Fakes.FakeDateTime,
  health_check_interval_ms: 3_000
