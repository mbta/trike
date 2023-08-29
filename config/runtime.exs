import Config

kinesis_stream = System.get_env("KINESIS_STREAM", "console")
splunk_token = System.get_env("TRIKE_SPLUNK_TOKEN", "")
sentry_env = System.get_env("SENTRY_ENV", "")
sentry_dsn = System.get_env("SENTRY_DSN", "")

config :trike,
  kinesis_stream: kinesis_stream

if kinesis_stream == "console" do
  # use fake client if logging to the console
  config :trike,
    kinesis_client: Fakes.FakeKinesisClient
end

if config_env() == :prod and splunk_token != "" do
  config :logger, Logger.Backend.Splunk,
    host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
    format: "$dateT$time $metadata[$level] node=$node $message\n",
    level: :info,
    token: splunk_token
end

if sentry_dsn != "" and sentry_env != "" do
  config :sentry,
    dsn: sentry_dsn,
    environment_name: sentry_env,
    enable_source_code_context: true,
    root_source_code_paths: [File.cwd!()],
    tags: %{
      env: sentry_env
    },
    included_environments: [sentry_env]

  config :logger, Sentry.LoggerBackend,
    level: :error,
    capture_log_messages: true
end

logger_backends =
  for {true, logger} <- [
        {true, :console},
        {sentry_dsn != "" and sentry_env != "", Sentry.LoggerBackend},
        {config_env() == :prod and splunk_token != "", Logger.Backend.Splunk}
      ],
      do: logger

config :logger, backends: logger_backends

case Integer.parse(System.get_env("LISTEN_PORT", "")) do
  {listen_port, ""} ->
    config :trike, :listen_port, listen_port

  _ ->
    :ok
end

case Integer.parse(System.get_env("STALE_TIMEOUT_MS", "")) do
  {timeout, ""} ->
    config :trike, :stale_timeout_ms, timeout

  _ ->
    :ok
end
