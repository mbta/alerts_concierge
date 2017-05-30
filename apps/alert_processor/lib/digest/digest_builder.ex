defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """
  alias AlertProcessor.{InformedEntityFilter, Model, Repo}
  alias Model.{Alert, Digest, Subscription}
  import Ecto.Query

  @doc """
  1. Takes a list of alerts
  2. Gets all users the alert affects
  3. Returns a list of Digest structs:
     [%Digest{user: user, alerts: [Alert]}]
  """
  @spec build_digests([Alert.t]) :: [Digest.t]
  def build_digests(alerts) do
    alerts
    |> Enum.map(fn(alert) ->
      {fetch_users(alert), alert}
    end)
    |> sort_by_user()
  end

  defp fetch_users(alert) do
    q = from s in Subscription, select: s
    {:ok, query, ^alert} = InformedEntityFilter.filter({:ok, q, alert})
    query
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.map(&(&1.user))
  end

  defp sort_by_user(data) do
    data
    |> Enum.reduce(%{}, fn({users, alert}, result) ->
      users
      |> Enum.reduce(result, fn(user, acc) ->
        Map.update(acc, user, [alert], &[alert | &1])
      end)
    end)
    |> Enum.map(fn({user, alerts}) ->
      %Digest{user: user, alerts: alerts}
    end)
  end
end
