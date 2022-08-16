import Config

config :trike,
  kinesis_client: Trike.KinesisClient

config :logger, backends: [:console]

config :logger, :console,
  format: "$dateT$time $metadata[$level] node=$node $message\n",
  level: :info

config :ehmon, :report_mf, {:ehmon, :info_report}
