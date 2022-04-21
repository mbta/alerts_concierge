defmodule AlertProcessor.Model.Query do
  @moduledoc "SQL queries used for reporting on the admin dashboard."

  alias AlertProcessor.Repo

  @type t :: %__MODULE__{id: String.t(), label: String.t(), query: String.t()}

  @enforce_keys [:label, :query]
  defstruct [:id] ++ @enforce_keys

  @notifications_enabled "u.communication_mode != 'none'"

  @subscription_counts """
    COUNT(s.*) AS total,
    COUNT(CASE WHEN s.paused IS NOT TRUE THEN 1 END) AS active,
    COUNT(DISTINCT u.id) AS users,
    COUNT(DISTINCT CASE WHEN s.paused IS NOT TRUE THEN u.id END) AS active_users
  """

  @users_with_subscriptions "users u JOIN subscriptions s ON u.id = s.user_id"

  defp email_replacements(replacements) do
    Enum.reduce(replacements, "users.email", fn {l, r}, acc ->
      "regexp_replace(#{acc}, '#{l}', '#{r}')"
    end)
  end

  defp email_replacements() do
    email_replacements([
      {"[ !,]", ""},
      {"@@*", "@"},
      {"(@gma$)|(@gmil.com)|(@g$)|(@gmail.co$)", "@gmail.com"},
      {"@aol$", "@aol.com"}
    ])
  end

  defp select_invalid_emails(select_clause) do
    """
    SELECT #{select_clause}
    FROM users
    WHERE users.email !~ '[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}'
    """
  end

  @doc "Lists available queries."
  @spec all() :: [t]
  def all do
    [
      %__MODULE__{
        label: "Subscription counts by type",
        query: """
        SELECT s.type,
          #{@subscription_counts}
        FROM #{@users_with_subscriptions}
        WHERE #{@notifications_enabled}
          AND s.return_trip IS NOT TRUE
        GROUP BY s.type
        ORDER BY s.type
        """
      },
      %__MODULE__{
        label: "Subscription counts by route",
        query: """
        SELECT s.route,
          #{@subscription_counts}
        FROM #{@users_with_subscriptions}
        WHERE #{@notifications_enabled}
          AND s.route IS NOT NULL
          AND s.return_trip IS NOT TRUE
        GROUP BY s.route
        ORDER BY s.route
        """
      },
      %__MODULE__{
        label: "Subscription counts by stop",
        query: """
        SELECT s.stop, s.route,
          #{@subscription_counts}
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
          JOIN users u ON s.user_id = u.id
        WHERE #{@notifications_enabled}
        GROUP BY s.stop, s.route
        ORDER BY s.stop, s.route
        """
      },
      %__MODULE__{
        label: "User counts by communication mode",
        query: """
        SELECT u.communication_mode,
          COUNT(DISTINCT u.id) AS users,
          COUNT(DISTINCT CASE WHEN s.id IS NOT NULL THEN u.id END) AS subscribed_users,
          COUNT(DISTINCT CASE WHEN s.id IS NOT NULL AND s.paused IS NOT TRUE THEN u.id END) AS active_users
        FROM users u
        LEFT JOIN subscriptions s ON u.id = s.user_id
        GROUP BY u.communication_mode
        """
      },
      %__MODULE__{
        label: "Weekly abandonment rate",
        query: """
        WITH
          periods AS (
            SELECT \"end\" - interval '1 week' AS start, \"end\"
            FROM generate_series(
              date_trunc('week', (SELECT MIN(inserted_at) FROM users)) - interval '1 second',
              date_trunc('week', NOW() AT TIME ZONE 'utc') + interval '1 week' - interval '1 second',
              interval '1 week'
            ) \"end\"
          ),
          new_users_per_period AS (
            SELECT COUNT(DISTINCT users.id) AS "count", periods.end AS period_end
            FROM users
            INNER JOIN periods ON (
              periods.start <= users.inserted_at
              AND users.inserted_at <= periods.end
            )
            WHERE
              users.email_rejection_status IS NULL
            GROUP BY
              periods.end
          ),
          new_users_without_subscriptions_per_period AS (
            SELECT COUNT(DISTINCT users.id) AS "count", periods.end AS period_end
            FROM users
            INNER JOIN periods ON (
              periods.start <= users.inserted_at
              AND users.inserted_at <= periods.end
            )
            LEFT JOIN subscriptions ON subscriptions.user_id = users.id
            WHERE
              users.email_rejection_status IS NULL
              AND subscriptions.id IS NULL
            GROUP BY
              periods.end
          )
        SELECT
          to_char(periods.end, 'YYYY-MM-DD') AS period_end,
          COALESCE(new_users_per_period.count, 0) AS new_users,
          COALESCE(new_users_without_subscriptions_per_period.count, 0) AS new_users_without_subscriptions
        FROM periods
        LEFT JOIN
          new_users_per_period
          ON new_users_per_period.period_end = periods.end
        LEFT JOIN
          new_users_without_subscriptions_per_period
          ON new_users_without_subscriptions_per_period.period_end = periods.end
        ORDER BY periods.end DESC
        """
      },
      %__MODULE__{
        label: "List user email fixes",
        query: """
        #{select_invalid_emails("users.email, #{email_replacements()} as fixed")}
        """
      },
      %__MODULE__{
        label: "Fix user emails",
        query: """
        UPDATE users
        SET
          email = #{email_replacements()},
          digest_opt_in = false
        WHERE email IN (
          #{select_invalid_emails("users.email")}
        )
        RETURNING email
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
