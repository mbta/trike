import Config

config :trike,
  kinesis_client: ExAws.Kinesis

config :logger, backends: [Logger.Backend.Splunk, :console]

config :logger, Logger.Backend.Splunk,
  host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
  format: "$dateT$time $metadata[$level] node=$node $message\n",
  level: :info

config :logger, :console, level: :warn
