defmodule AlertProcessor.Repo do
  use Ecto.Repo,
    otp_app: :alert_processor,
    adapter: Ecto.Adapters.Postgres

  require Logger

  def before_connect(config) do
    Logger.info("generating_aws_rds_iam_auth_token")
    Logger.info("important config #{Enum.map(config, fn {k,v} -> "#{k}:#{v}" end) |> Enum.join(", ")}")
    username = "alerts_concierge"
    hostname = Keyword.fetch!(config, :hostname)
    port = Keyword.fetch!(config, :port)
    mod = Application.get_env(:alert_processor, :aws_rds_mod)
    Logger.info("username: #{username}, hostname: #{hostname}, port: #{port}, mod: #{mod}")
    token = mod.generate_db_auth_token(hostname, username, port, %{})
    Logger.info("generated_aws_rds_iam_auth_token")

    Keyword.put(config, :password, token)
  end
end
