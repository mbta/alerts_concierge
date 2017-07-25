defmodule ConciergeSite.UserParams do
  @moduledoc """
  Functions for processing user input from account updates and creation
  """

  alias AlertProcessor.Helpers.DateTimeHelper
  alias Calendar.DateTime

  @doc """
  Map radio button selections from Update Account page to appropriate user attributes
  """
  @spec prepare_for_update_changeset(map) :: map
  def prepare_for_update_changeset(params) do
    phone_number =
      case params["sms_toggle"] do
        "true" -> %{"phone_number" => String.replace(params["phone_number"], ~r/\D/, "")}
        "false" -> %{"phone_number" => nil}
        _ -> %{}
      end

    do_not_disturb =
      case params["dnd_toggle"] do
        "true" ->
          %{"do_not_disturb_start" => DateTimeHelper.timestamp_to_utc(params["do_not_disturb_start"]),
            "do_not_disturb_end" => DateTimeHelper.timestamp_to_utc(params["do_not_disturb_end"])}
        "false" ->
          %{"do_not_disturb_start" => nil, "do_not_disturb_end" => nil}
        _ -> %{}
      end

    params
    |> Map.take(["amber_alert_opt_in"])
    |> Map.merge(phone_number)
    |> Map.merge(do_not_disturb)
  end

  @doc """
  Convert date string values in map of %{vacation_start: MM/DD/YYYY, vacation_end: MM/DD/YYYY }
  to DateTimes
  """
  @spec convert_vacation_strings_to_datetimes(map) :: map
  def convert_vacation_strings_to_datetimes(%{"vacation_start" => vacation_start, "vacation_end" => vacation_end}) do
    [start_month, start_day, start_year] = parse_date_string(vacation_start)
    [end_month, end_day, end_year] = parse_date_string(vacation_end)

    %{"vacation_start" => DateTime.from_erl!({{start_year, start_month, start_day}, {0, 0, 0}}, "Etc/UTC"),
      "vacation_end" => DateTime.from_erl!({{end_year, end_month, end_day}, {0, 0, 0}}, "Etc/UTC") }
  end

  defp parse_date_string(date_string) do
    date_string
    |> String.split("/")
    |> Enum.map(&String.to_integer/1)
  end
end
