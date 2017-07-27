defmodule UserParamsTest do
  use ExUnit.Case
  alias ConciergeSite.UserParams

  describe "convert_vacation_strings_to_datetimes/1" do
    test "returns a tuple of {:ok, vacation_dates} with valid dates"do
      user_params = %{
        "vacation_start" => "10/31/2017",
        "vacation_end" => "11/15/2017",
      }

      datetimes = UserParams.convert_vacation_strings_to_datetimes(user_params)

      assert datetimes == {:ok, %{
        "vacation_end" =>
          %DateTime{calendar: Calendar.ISO, day: 15, hour: 0, microsecond: {0, 0},
            minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "Etc/UTC",
            utc_offset: 0, year: 2017, zone_abbr: "UTC"},
        "vacation_start" =>
          %DateTime{calendar: Calendar.ISO, day: 31, hour: 0, microsecond: {0, 0},
            minute: 0, month: 10, second: 0, std_offset: 0, time_zone: "Etc/UTC",
            utc_offset: 0, year: 2017, zone_abbr: "UTC"}
      }}
    end

    test "returns :error when either date string does not match MM/DD/YYYY format" do
      user_params = %{
        "vacation_start" => "Oct 31, 2017",
        "vacation_end" => "Two weeks later",
      }

      assert :error = UserParams.convert_vacation_strings_to_datetimes(user_params)
    end

    test "returns :error when either date string does not correspond to a real date" do
      user_params = %{
        "vacation_start" => "10/41/2017",
        "vacation_end" => "66/77/2017",
      }

      assert :error = UserParams.convert_vacation_strings_to_datetimes(user_params)
    end
  end
end
