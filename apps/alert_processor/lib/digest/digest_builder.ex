defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """
  alias AlertProcessor.{InformedEntityFilter, Model, Repo}
  alias Model.{Alert, Digest, DigestDateGroup, User, Subscription}

  @doc """
  1. Takes a list of alerts
  2. Gets all users the alert affects
  3. Returns a list of Digest structs:
     [%Digest{user: user, alerts: [Alert]}]
  """
  @spec build_digests({[Alert.t], DigestDateGroup.t}) :: [Digest.t]
  def build_digests({alerts, digest_date_group}) do
    subs =
      Subscription
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)

    alerts
    |> Enum.map(fn(alert) ->
      {fetch_active_users(alert, subs), alert}
    end)
    |> sort_by_user(digest_date_group)
  end

  defp fetch_active_users(alert, subs) do
    subs
    |> InformedEntityFilter.filter(alert: alert)
    |> Enum.map(&(&1.user))
    |> Enum.filter(&(!User.is_disabled?(&1)))
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
