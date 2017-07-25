defmodule UserParamsTest do
  use ExUnit.Case
  alias ConciergeSite.UserParams

  test "convert_vacation_strings_to_datetimes" do
    user_params = %{
      "vacation_start" => "10/31/2017",
      "vacation_end" => "11/15/2017",
    }

    datetimes = UserParams.convert_vacation_strings_to_datetimes(user_params)

    assert datetimes == %{
      "vacation_end" =>
        %DateTime{calendar: Calendar.ISO, day: 15, hour: 0, microsecond: {0, 0},
          minute: 0, month: 11, second: 0, std_offset: 0, time_zone: "Etc/UTC",
          utc_offset: 0, year: 2017, zone_abbr: "UTC"},
      "vacation_start" =>
        %DateTime{calendar: Calendar.ISO, day: 31, hour: 0, microsecond: {0, 0},
          minute: 0, month: 10, second: 0, std_offset: 0, time_zone: "Etc/UTC",
          utc_offset: 0, year: 2017, zone_abbr: "UTC"}
    }
  end
end
