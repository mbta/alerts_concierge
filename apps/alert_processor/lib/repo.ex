defmodule AlertProcessor.Repo do
  use Ecto.Repo, otp_app: :alert_processor
  @dialyzer {:nowarn_function, rollback: 1}

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
   {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL_#{database_suffix()}"))}
  end

  defp database_suffix do
    System.get_env("MIX_ENV") || "DEV"
  end
end
