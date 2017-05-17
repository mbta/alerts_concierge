defmodule AlertProcessor.Helpers.DateTimeHelperTest do
  use ExUnit.Case
  alias AlertProcessor.Helpers.DateTimeHelper, as: DTH

  @interval 604_800 # 1 Week in seconds
  @sunday 7
  @time_of_day ~T[21:00:00]

  test "seconds_until_next_digest/3 returns seconds between now and a specific day/time" do
    tuesday_8pm_utc = {~D[2017-05-16], ~T[20:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            @sunday,
                                            @time_of_day,
                                            tuesday_8pm_utc)

    assert seconds == 435_600
  end

  test "seconds_until_next_digest/3 handles day of week before current day of week" do
    sunday_8pm_utc = {~D[2017-05-21], ~T[20:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            6,
                                            @time_of_day,
                                            sunday_8pm_utc)

    assert seconds == 687_600
  end

  test "seconds_until_next_digest/3 handles time of day earlier than current" do
    tuesday_8pm_utc = {~D[2017-05-16], ~T[20:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            @sunday,
                                            ~T[12:00:00],
                                            tuesday_8pm_utc)

    assert seconds == 403_200
  end
end
