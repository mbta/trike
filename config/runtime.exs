import Config

kinesis_stream = System.get_env("KINESIS_STREAM", "console")

config :trike,
  listen_port: System.get_env("LISTEN_PORT", "8001") |> String.to_integer(),
  kinesis_stream: kinesis_stream

if config_env() == :prod do
  config :logger, Logger.Backend.Splunk, token: System.get_env("TRIKE_SPLUNK_TOKEN")

if kinesis_stream == "console" do
  # use fake client if logging to the console
  config :trike,
    kinesis_client: Fakes.FakeKinesisClient
end

