defmodule AlertProcessor.Repo do
  use Ecto.Repo, otp_app: :alert_processor

  alias AlertProcessor.Helpers.ConfigHelper

  @dialyzer {:nowarn_function, rollback: 1}

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, ConfigHelper.get_string(:database_url))}
  end
end
