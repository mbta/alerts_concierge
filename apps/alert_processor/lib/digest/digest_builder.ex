defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """
  alias AlertProcessor.{InformedEntityFilter, Model, Repo}
  alias Model.{Alert, Subscription}
  import Ecto.Query

  @doc """
  1. Takes a list of alerts
  2. Gets all users the alert affects
  3. Returns a map with user ids as keys,
     and an array of relevant alerts as value:

     %{
       "abc123" => [%Alert{}]
     }
  """
  @spec build_digests([Alert.t]) :: map
  def build_digests(alerts) do
    alerts
    |> Enum.map(fn(alert) ->
      {fetch_user_ids(alert), alert}
    end)
    |> List.flatten
    |> sort_by_user
  end

  defp fetch_user_ids(alert) do
    q = from s in Subscription, select: s
    {:ok, query, ^alert} = InformedEntityFilter.filter({:ok, q, alert})
    query
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.map(&(&1.user.id))
  end

  defp sort_by_user(data) do
    data
    |> Enum.reduce(%{}, fn({ids, alert}, result) ->
      ids
      |> Enum.reduce(result, fn(id, acc) ->
        values = Map.get(acc, id) || []
        values = values ++ [alert]
        Map.put(acc, id, values)
      end)
    end)
  end
end
