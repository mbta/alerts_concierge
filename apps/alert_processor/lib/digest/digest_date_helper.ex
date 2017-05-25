defmodule AlertProcessor.DigestDateHelper do
  @moduledoc """
  Determines which digest date groups an alert belongs in
  """

  alias AlertProcessor.{Model.DigestDateGroup, Helpers.DateTimeHelper}
  alias Calendar.DateTime, as: DT

  @spec calculate_date_groups([Alert.t], DateTime.t | nil) :: [Alert.t]
  def calculate_date_groups(alerts, time \\ nil) do
    today = time || DT.now!("America/New_York")
    Enum.map(alerts, &calculate_date_group(&1, determine_digest_groups(today)))
  end

  @spec calculate_date_group(Alert.t, map) :: Alert.t
  defp calculate_date_group(alert, digest_groups) do
    groups = Enum.flat_map(Map.from_struct(digest_groups), fn {name, group} ->
      if active_period_matches?(alert.active_period, group) do
        [name]
      else
        []
      end
    end)
    Map.put(alert, :digest_groups, groups)
  end

  @spec active_period_matches?({DateTime.t, DateTime.t}, {DateTime.t, DateTime.t})
    :: boolean()
  defp active_period_matches?(active_periods, digest_group) do
    Enum.any?(active_periods, fn(ap) ->
      active_period_within?(ap, digest_group)
    end)
  end

  @spec determine_digest_groups(DateTime.t) :: map
  defp determine_digest_groups(time) do
    %DigestDateGroup{
      upcoming_weekend: DateTimeHelper.upcoming_weekend(time),
      upcoming_week: DateTimeHelper.upcoming_week(time),
      next_weekend: DateTimeHelper.next_weekend(time),
      future: DateTimeHelper.future(time)
     }
  end

  @spec active_period_within?(map, {DateTime.t, DateTime.t}) :: boolean()
  defp active_period_within?(%{start: aps, end: ape}, {dgs, dge}) do
    not DT.before?(dge, aps) and not DT.before?(ape, dgs)
  end
end
