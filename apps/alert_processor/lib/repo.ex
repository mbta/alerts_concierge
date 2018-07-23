defmodule AlertProcessor.Repo do
  use Ecto.Repo, otp_app: :alert_processor
  use Scrivener
  @dialyzer {:nowarn_function, rollback: 1}
  alias AlertProcessor.Helpers.ConfigHelper

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, ConfigHelper.get_string(:database_url))}
  end
end
