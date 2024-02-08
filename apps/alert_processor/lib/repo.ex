defmodule AlertProcessor.Repo do
  use Ecto.Repo,
    otp_app: :alert_processor,
    adapter: Ecto.Adapters.Postgres

  require Logger

  def before_connect(config) do
    port = System.get_env("DATABASE_PORT") |> String.to_integer()
    hostname = System.get_env("DATABASE_HOST")
    username = System.get_env("DATABASE_USER")
    mod = Application.get_env(:alert_processor, :aws_rds_mod)
    Logger.info("username: #{username}, hostname: #{hostname}, port: #{port}, mod: #{mod}")
    Logger.info("generating_aws_rds_iam_auth_token")
    token = mod.generate_db_auth_token(hostname, username, port, %{})

    if is_nil(token) do
      Logger.info("#{__MODULE__} add_prod_credentials token_is_nil")
    else
      Logger.info("generated_aws_rds_iam_auth_token")
    end

    Keyword.merge(config,
      hostname: hostname,
      username: username,
      port: port,
      password: token,
      ssl_opts: [
        cacertfile: "priv/aws-cert-bundle.pem",
        verify: :verify_peer,
        server_name_indication: String.to_charlist(hostname),
        verify_fun:
          {&:ssl_verify_hostname.verify_fun/3, [check_hostname: String.to_charlist(hostname)]}
      ]
    )
  end
end
