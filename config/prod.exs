import Config

config :trike,
  kinesis_client: Trike.KinesisClient

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, "default", 30}],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, "default", 30}
  ]

config :logger, backends: [:console]

config :logger, :console,
  format: "$dateT$time $metadata[$level] node=$node $message\n",
  level: :info

config :ehmon, :report_mf, {:ehmon, :info_report}
