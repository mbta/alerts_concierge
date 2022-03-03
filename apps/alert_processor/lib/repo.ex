defmodule AlertProcessor.Repo do
  use Ecto.Repo,
    otp_app: :alert_processor,
    adapter: Ecto.Adapters.Postgres
end
