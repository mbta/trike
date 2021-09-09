import Config

config :trike,
  listen_port: System.get_env("LISTEN_PORT", "8001") |> String.to_integer(),
  kinesis_stream: System.get_env("KINESIS_STREAM", "console")

if config_env() == :prod do
  config :logger, Logger.Backend.Splunk, token: System.get_env("TRIKE_SPLUNK_TOKEN")
end
