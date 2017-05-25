defmodule AlertProcessor.DigestSerializer do
  @moduledoc """
  Converts alerts into digest email text
  """
  alias AlertProcessor.{Model, Helpers.DateTimeHelper}
  alias Model.{Alert, Digest}
  alias Calendar.DateTime, as: DT

  @doc """
  Takes a Digest and serializes each alert into
  the structure it will be presented in an email
  """
  @spec serialize(Digest.t) :: [{String.t, [Alert.t]}]
  def serialize(digest, time \\ nil) do
    time = time || DT.now!("America/New_York")
    digest.alerts
    |> group_by_digest_section(time)
  end

  defp group_by_digest_section(alerts, time) do
    [
      {
        header("This Weekend", DateTimeHelper.upcoming_weekend(time)),
        filter_by_group(alerts, :upcoming_weekend)
      },
      {
        header("Next Week", DateTimeHelper.upcoming_week(time)),
        filter_by_group(alerts, :upcoming_week)
      },
      {
        header("Next Weekend", DateTimeHelper.next_weekend(time)),
        filter_by_group(alerts, :next_weekend)
      },
      {
        header("Future Alerts", DateTimeHelper.future(time)),
        filter_by_group(alerts, :future)
      }
    ]
    |> Enum.reject(fn({_h, alerts}) ->
      Enum.empty?(alerts)
    end)
  end

  defp header(prefix, {start_date, end_date}) do
    range_text = if start_date.month == end_date.month do
      "#{DateTimeHelper.month_name(start_date.month)} #{start_date.day} - #{end_date.day}"
    else
      "#{DateTimeHelper.month_name(start_date.month)} #{start_date.day} - #{DateTimeHelper.month_name(end_date.month)} #{end_date.day}"
    end

    "#{prefix}, #{range_text}"
  end

  defp filter_by_group(alerts, digest_group_name) do
    Enum.filter(
      alerts,
      &(Enum.member?(&1.digest_groups, digest_group_name))
   )
  end
end
