import Config

config :trike,
  listen_port: System.get_env("LISTEN_PORT"),
  kinesis_stream: System.get_env("KINESIS_STREAM")

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
