defmodule AlertProcessor.Metrics.UserMetrics do
  alias AlertProcessor.Repo

  def counts_by_type() do
    query = """
    SELECT SUM(CASE WHEN phone_number IS NULL THEN 0 ELSE 1 END) AS phone_count, SUM(CASE WHEN phone_number IS NULL THEN 1 ELSE 0 END) AS email_count FROM users
    """

    case Ecto.Adapters.SQL.query(Repo, query, []) do
      {:ok, %{rows: [data]}} -> data
      _ -> [nil, nil]
    end
  end
end
