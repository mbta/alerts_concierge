defmodule AlertProcessor.Model.Query do
  @moduledoc "SQL queries used for reporting on the admin dashboard."

  alias AlertProcessor.Repo

  @type t :: %__MODULE__{id: String.t(), label: String.t(), query: String.t()}

  @enforce_keys [:label, :query]
  defstruct [:id] ++ @enforce_keys

  @subscription_counts """
    COUNT(*) AS total,
    COUNT(CASE WHEN paused IS NOT TRUE THEN 1 END) AS active,
    COUNT(DISTINCT user_id) AS users,
    COUNT(DISTINCT CASE WHEN paused IS NOT TRUE THEN user_id END) AS active_users
  """

  @doc "Lists available queries."
  @spec all() :: [t]
  def all do
    [
      %__MODULE__{
        label: "Subscription counts by type",
        query: """
        SELECT type,
          #{String.trim(@subscription_counts)}
        FROM subscriptions
        WHERE return_trip IS NOT TRUE
        GROUP BY type
        ORDER BY type
        """
      },
      %__MODULE__{
        label: "Subscription counts by route",
        query: """
        SELECT route,
          #{String.trim(@subscription_counts)}
        FROM subscriptions
        WHERE route IS NOT NULL
          AND return_trip IS NOT TRUE
        GROUP BY route
        ORDER BY route
        """
      },
      %__MODULE__{
        label: "Subscription counts by stop",
        query: """
        SELECT stop, route,
          #{String.trim(@subscription_counts)}
        FROM (
          SELECT user_id, paused, route, origin AS stop
            FROM subscriptions
            WHERE origin IS NOT NULL
              AND return_trip IS NOT TRUE
          UNION ALL
          SELECT user_id, paused, route, destination AS stop
            FROM subscriptions
            WHERE origin != destination
              AND destination IS NOT NULL
              AND return_trip IS NOT TRUE
        ) s
        GROUP BY stop, route
        ORDER BY stop, route
        """
      },
      %__MODULE__{
        label: "User counts by communication mode",
        query: """
        SELECT communication_mode,
          COUNT(DISTINCT users.id) AS users,
          COUNT(DISTINCT CASE WHEN subscriptions.id IS NOT NULL THEN users.id END) AS active_users
        FROM users
        LEFT JOIN subscriptions
          ON users.id = subscriptions.user_id
            AND subscriptions.paused IS NOT TRUE
        GROUP BY communication_mode
        """
      }
    ]
    |> Enum.map(&%{&1 | id: &1.label |> String.downcase() |> String.replace(" ", "_")})
  end

  @doc "Fetches a query by ID."
  @spec get(String.t()) :: t | nil
  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "Executes the given query."
  @spec execute!(t) :: Postgrex.Result.t()
  def execute!(%__MODULE__{query: query}), do: Repo.query!(query)
end
