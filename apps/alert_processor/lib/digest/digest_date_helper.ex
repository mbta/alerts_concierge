defmodule AlertProcessor.DigestDateHelper do
  @moduledoc """
  Determines which digest date groups an alert belongs in
  """

  alias AlertProcessor.{Model.Alert, Model.DigestDateGroup, Helpers.DateTimeHelper}
  alias Calendar.DateTime, as: DT

  @spec calculate_date_groups([Alert.t], DateTime.t | nil)
  :: {[Alert.t], DigestDateGroup.t}
  def calculate_date_groups(alerts, time \\ nil) do
    today = time || DT.now!("America/New_York")
    result = Enum.reduce(
      alerts,
      determine_digest_group(today),
      &calculate_date_group(&1, &2)
    )

    {alerts, Map.merge(%DigestDateGroup{}, result)}
  end

  @spec calculate_date_group(Alert.t, map) :: Alert.t
  defp calculate_date_group(alert, digest_date_group) do
    groups = [:upcoming_weekend, :upcoming_week, :next_weekend, :future]

    alert.active_period
    |> matching_groups(digest_date_group, groups)
    |> Enum.reduce(digest_date_group, fn(name, acc) ->
      {_res, acc} = get_and_update_in(acc, [name, :alert_ids], &{&1, &1 ++ [alert.id]})
      acc
    end)
  end

  @spec matching_groups([map], map, [atom]) :: [map]
  defp matching_groups([], _, _), do: []
  defp matching_groups(_, _, []), do: []
  defp matching_groups([period | ptail] = periods, ddg, [group | gtail]) do
    timeframe = get_in(ddg, [group, :timeframe])

    if active_period_within?(period, timeframe) do
      [group | matching_groups(ptail, ddg, gtail)]
    else
      matching_groups(periods, ddg, gtail)
    end
  end

  @spec determine_digest_group(DateTime.t) :: map
  defp determine_digest_group(time) do
    %{
      upcoming_weekend: %{
        timeframe: DateTimeHelper.upcoming_weekend(time),
        alert_ids: []
      },
      upcoming_week: %{
        timeframe: DateTimeHelper.upcoming_week(time),
        alert_ids: []
      },
      next_weekend: %{
        timeframe: DateTimeHelper.next_weekend(time),
        alert_ids: []
      },
      future: %{
        timeframe: DateTimeHelper.future(time),
        alert_ids: []
      }
    }
  end

  @spec active_period_within?(map, {DateTime.t, DateTime.t}) :: boolean()
  defp active_period_within?(%{start: aps, end: nil}, {_dgs, dge}) do
    DT.before?(aps, dge)
  end
  defp active_period_within?(%{start: aps, end: ape}, {dgs, dge}) do
    !DT.before?(dge, aps) && !DT.before?(ape, dgs)
  end
end
