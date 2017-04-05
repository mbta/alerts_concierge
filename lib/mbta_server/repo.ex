defmodule MbtaServer.Repo do
  use Ecto.Repo, otp_app: :mbta_server
  @dialyzer {:nowarn_function, rollback: 1}

  @doc """		
  Dynamically loads the repository url from the		
  DATABASE_URL environment variable.		
  """		
  def init(_, opts) do		
   {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL_#{database_suffix}"))}
  end

  defp database_suffix do
    Mix.env
    |> Atom.to_string
    |> String.upcase
  end
end
