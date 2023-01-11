import Config

config :trike,
  # use a random port
  listen_port: 0,
  clock: Fakes.FakeDateTime

config :logger, :console, level: :warn
