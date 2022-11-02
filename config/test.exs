import Config

config :trike,
  clock: Fakes.FakeDateTime

config :logger, :console, level: :warn
