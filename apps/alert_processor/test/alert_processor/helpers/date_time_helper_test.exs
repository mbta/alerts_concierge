defmodule AlertProcessor.Helpers.DateTimeHelperTest do
  use ExUnit.Case
  alias AlertProcessor.Helpers.DateTimeHelper, as: DTH
  alias Calendar.DateTime, as: DT

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

  describe "digest groups" do
    @thursday DT.from_erl!({{2017, 5, 25}, {0, 0, 0}}, "America/New_York")
    @saturday DT.from_erl!({{2017, 5, 27}, {0, 0, 0}}, "America/New_York")
    @sunday DT.from_erl!({{2017, 5, 28}, {0, 0, 0}}, "America/New_York")

    test "upcoming_weekend/0 returns the start and end DateTime of upcoming weekend" do
      saturday_start = DT.from_erl!({{2017, 5, 27}, {0, 0, 0}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 5, 28}, {23, 59, 59}}, "America/New_York")

      assert DTH.upcoming_weekend(@thursday) == {saturday_start, sunday_end}
    end

    test "upcoming_weekend/0 works for current date of Saturday/Sunday" do
      saturday_start = DT.from_erl!({{2017, 6, 03}, {0, 0, 0}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 6, 04}, {23, 59, 59}}, "America/New_York")

      assert DTH.upcoming_weekend(@saturday) == {saturday_start, sunday_end}
      assert DTH.upcoming_weekend(@sunday) == {saturday_start, sunday_end}
    end

    test "upcoming_week/0" do
      monday_start = DT.from_erl!({{2017, 5, 29}, {0, 0, 0}}, "America/New_York")
      friday_end = DT.from_erl!({{2017, 6, 2}, {23, 59, 59}}, "America/New_York")

      assert DTH.upcoming_week(@thursday) == {monday_start, friday_end}
    end

    test "next_weekend/0" do
      saturday_start = DT.from_erl!({{2017, 6, 3}, {0, 0, 0}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 6, 4}, {23, 59, 59}}, "America/New_York")

      assert DTH.next_weekend(@thursday) == {saturday_start, sunday_end}
    end

    test "future/0" do
      monday_start = DT.from_erl!({{2017, 6, 5}, {0, 0, 0}}, "America/New_York")
      far_in_future = DT.from_erl!({{3000, 01, 01}, {0, 0, 0}}, "America/New_York")

      assert DTH.future(@thursday) == {monday_start, far_in_future}
    end
  end
end
