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
        label: "Monthly new active users",
        query: """
        WITH
          periods AS (
            SELECT start, start + interval '1 month' - interval '1 day' as \"end\"
            FROM generate_series(
              date_trunc('month', (SELECT MIN(inserted_at) FROM users)),
              date_trunc('month', NOW() AT TIME ZONE 'utc') + interval '1 month' - interval '1 second',
              interval '1 month'
            ) start
          ),
          new AS (
            SELECT COUNT(DISTINCT users.id), periods.end AS period_end
            FROM users
            INNER JOIN subscriptions ON (
              subscriptions.user_id = users.id
              AND subscriptions.paused = false
            )
            INNER JOIN periods ON (
              periods.start <= users.inserted_at
              AND users.inserted_at < periods.end
            )
            WHERE users.communication_mode IN ('email', 'sms')
            GROUP BY periods.end
          ),
          users_before_end AS (
            SELECT COUNT(DISTINCT users.id), periods.end AS period_end
            FROM users
            INNER JOIN subscriptions ON (
              subscriptions.user_id = users.id
              AND subscriptions.paused = false
            )
            INNER JOIN periods ON (
              users.inserted_at < periods.end
            )
            WHERE users.communication_mode IN ('email', 'sms')
            GROUP BY periods.end
          )
        SELECT
          to_char(periods.end, 'YYYY-MM-DD') AS period_end,
          COALESCE(new.count, 0) AS new_active_users,
          COALESCE(users_before_end.count, 0) AS total_active_users
        FROM periods
        LEFT JOIN new ON new.period_end = periods.end
        LEFT JOIN users_before_end ON users_before_end.period_end = periods.end
        ORDER BY periods.end DESC
        """
      },
      %__MODULE__{
        label: "Grouped Time Windows",
        query: """
        SELECT
          to_char(s.start_time, 'FMHH24:MI') as start_time,
          to_char(s.end_time, 'FMHH24:MI') as end_time, s.type,
          count(distinct s.id)
        FROM subscriptions s
        GROUP BY s.type, s.start_time, s.end_time;
        """
      },
      %__MODULE__{
        label: "Fully Paused Accounts",
        query: """
          WITH
          paused_accounts AS (
            SELECT u.id, MAX(s.updated_at) as newest_subscription FROM users u
            INNER JOIN subscriptions s ON u.id = s.user_id
            GROUP BY u.id
            HAVING sum(case when s.paused = false then 1 else 0 end) = 0
          ),
          total_accounts AS (
            SELECT COUNT(DISTINCT paused_accounts.id) as total_paused_accounts FROM paused_accounts
          ),
          paused_for_less_than_a_month AS (
            SELECT COUNT(DISTINCT paused_accounts.id) as total_paused_accounts FROM paused_accounts
            WHERE paused_accounts.newest_subscription > NOW() - INTERVAL '1 month'
          ),
          paused_for_less_than_three_months AS (
            SELECT COUNT(DISTINCT paused_accounts.id) as total_paused_accounts FROM paused_accounts
            WHERE paused_accounts.newest_subscription > NOW() - INTERVAL '3 months'
          ),
          paused_for_less_than_twelve_months AS (
            SELECT COUNT(DISTINCT paused_accounts.id) as total_paused_accounts FROM paused_accounts
            WHERE paused_accounts.newest_subscription > NOW() - INTERVAL '12 months'
          ),
          paused_for_twelve_months_or_more AS (
            SELECT COUNT(DISTINCT paused_accounts.id) as total_paused_accounts FROM paused_accounts
            WHERE paused_accounts.newest_subscription <= NOW() - INTERVAL '12 months'
          )
          SELECT 'Total Paused Accounts' as Time_Span,ta.total_paused_accounts as total_accounts from total_accounts ta
          UNION ALL
          SELECT 'Paused for Less than 1 month',pl1.total_paused_accounts FROM paused_for_less_than_a_month pl1
          UNION ALL
          SELECT 'Paused for Less than 3 months',pl3.total_paused_accounts FROM paused_for_less_than_three_months pl3
          UNION ALL
          SELECT 'Paused for Less than 12 months',pl12.total_paused_accounts FROM paused_for_less_than_twelve_months pl12
          UNION ALL
          SELECT 'Paused for 12 months or more',plmore.total_paused_accounts FROM paused_for_twelve_months_or_more plmore;
        """
      },
      %__MODULE__{
        label: "Count of Users With Parallel Bus Route Subscriptions",
        query: """
        SELECT COUNT(DISTINCT user_id) AS users_with_parallel_subscriptions
        FROM subscriptions
        WHERE id IN
        (SELECT parent_id FROM subscriptions
        WHERE parent_id IS NOT null
        AND paused is not true
        GROUP BY parent_id)
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
