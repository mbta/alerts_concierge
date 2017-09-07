defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """
  alias AlertProcessor.{InformedEntityFilter, Model, Repo}
  alias Model.{Alert, Digest, DigestDateGroup, Subscription}

  @doc """
  1. Takes a list of alerts
  2. Gets all users the alert affects
  3. Returns a list of Digest structs:
     [%Digest{user: user, alerts: [Alert]}]
  """
  @spec build_digests({[Alert.t], DigestDateGroup.t}, integer) :: [Digest.t]
  def build_digests({alerts, digest_date_group}, digest_interval) do
    subs =
      Subscription
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)

    alerts
    |> Enum.map(fn(alert) ->
      {fetch_active_users(alert, subs, digest_interval), alert}
    end)
    |> sort_by_user(digest_date_group)
  end

  defp fetch_active_users(alert, subs, digest_interval) do
    next_digest_sent_at = (DateTime.utc_now() |> DateTime.to_unix()) + digest_interval
    subs
    |> InformedEntityFilter.filter(alert: alert)
    |> Enum.map(&(&1.user))
    |> Enum.filter(fn user ->
      is_nil(user.vacation_end) or DateTime.to_unix(user.vacation_end) < next_digest_sent_at
    end)
  end

  defp sort_by_user(data, digest_date_group) do
    data
    |> Enum.reduce(%{}, fn({users, alert}, result) ->
      users
      |> Enum.reduce(result, fn(user, acc) ->
        Map.update(acc, user, [alert], &[alert | &1])
      end)
    end)
    |> Enum.map(fn({user, alerts}) ->
      %Digest{user: user, alerts: Enum.uniq(alerts), digest_date_group: digest_date_group}
    end)
  end
end
