import Config

config :trike,
  kinesis_client: Trike.KinesisClient,
  is_prod?: true

config :logger, :console, level: :info

config :ehmon, :report_mf, {:ehmon, :info_report}
