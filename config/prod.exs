import Config

config :trike,
  kinesis_client: Trike.KinesisClient

config :logger,
  backends: [Logger.Backend.Splunk, :console],
  utc_log: true

config :logger, Logger.Backend.Splunk,
  host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
  format: "$dateT$time $metadata[$level] node=$node $message\n",
  level: :info

config :logger, :console, level: :warn

config :ehmon, :report_mf, {:ehmon, :info_report}
