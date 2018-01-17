defmodule AlertProcessor.Helpers.DateTimeHelperTest do
  use ExUnit.Case
  alias AlertProcessor.Helpers.DateTimeHelper, as: DTH
  alias Calendar.DateTime, as: DT
  alias Calendar.Time, as: T

  @interval 604_800 # 1 Week in seconds
  @thursday 4
  @time_of_day ~T[21:00:00]

  test "time_without_zone/1" do
    assert ~T[12:10:00.000] = DTH.time_without_zone("2015-01-23T12:10:00.000+02:30")
  end

  test "seconds_until_next_digest/3 returns seconds between now and a specific day/time" do
    tuesday_8pm_utc = {~D[2017-05-16], ~T[20:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            @thursday,
                                            @time_of_day,
                                            tuesday_8pm_utc)

    unix_now = DateTime.from_naive!(~N[2017-05-16 20:00:00], "Etc/UTC") |> DateTime.to_unix()
    send_at_datetime = DateTime.from_unix!(unix_now + seconds)
    assert DateTime.compare(send_at_datetime, DateTime.from_naive!(~N[2017-05-18 21:00:00], "Etc/UTC")) == :eq
    assert Date.day_of_week(send_at_datetime) == @thursday
    assert T.diff(DateTime.to_time(send_at_datetime), @time_of_day) == 0
  end

  test "seconds_until_next_digest/3 handles day of week before current day of week" do
    sunday_8pm_utc = {~D[2017-05-21], ~T[20:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            6,
                                            @time_of_day,
                                            sunday_8pm_utc)

    unix_now = DateTime.from_naive!(~N[2017-05-21 20:00:00], "Etc/UTC") |> DateTime.to_unix()
    send_at_datetime = DateTime.from_unix!(unix_now + seconds)
    assert DateTime.compare(send_at_datetime, DateTime.from_naive!(~N[2017-05-27 21:00:00], "Etc/UTC")) == :eq
    assert Date.day_of_week(send_at_datetime) == 6
    assert T.diff(DateTime.to_time(send_at_datetime), @time_of_day) == 0
  end

  test "seconds_until_next_digest/3 handles time of day earlier than current" do
    tuesday_8pm_utc = {~D[2017-05-16], ~T[09:00:00]}
    seconds = DTH.seconds_until_next_digest(@interval,
                                            @thursday,
                                            ~T[12:00:00],
                                            tuesday_8pm_utc)

    unix_now = DateTime.from_naive!(~N[2017-05-16 09:00:00], "Etc/UTC") |> DateTime.to_unix()
    send_at_datetime = DateTime.from_unix!(unix_now + seconds)
    assert DateTime.compare(send_at_datetime, DateTime.from_naive!(~N[2017-05-18 12:00:00], "Etc/UTC")) == :eq
    assert Date.day_of_week(send_at_datetime) == @thursday
    assert T.diff(DateTime.to_time(send_at_datetime), ~T[12:00:00]) == 0
  end

  describe "digest groups" do
    @thursday DT.from_erl!({{2017, 5, 25}, {0, 0, 0}}, "America/New_York")
    @saturday DT.from_erl!({{2017, 5, 27}, {0, 0, 0}}, "America/New_York")
    @sunday DT.from_erl!({{2017, 5, 28}, {0, 0, 0}}, "America/New_York")

    test "upcoming_weekend/0 returns the start and end DateTime of upcoming weekend" do
      saturday_start = DT.from_erl!({{2017, 5, 27}, {2, 30, 1}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 5, 29}, {2, 30, 0}}, "America/New_York")

      assert DTH.upcoming_weekend(@thursday) == {saturday_start, sunday_end}
    end

    test "upcoming_weekend/0 works for current date of Saturday/Sunday" do
      saturday_start = DT.from_erl!({{2017, 6, 03}, {2, 30, 1}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 6, 05}, {2, 30, 0}}, "America/New_York")

      assert DTH.upcoming_weekend(@saturday) == {saturday_start, sunday_end}
      assert DTH.upcoming_weekend(@sunday) == {saturday_start, sunday_end}
    end

    test "upcoming_week/0" do
      monday_start = DT.from_erl!({{2017, 5, 29}, {2, 30, 1}}, "America/New_York")
      friday_end = DT.from_erl!({{2017, 6, 3}, {2, 30, 0}}, "America/New_York")

      assert DTH.upcoming_week(@thursday) == {monday_start, friday_end}
    end

    test "next_weekend/0" do
      saturday_start = DT.from_erl!({{2017, 6, 3}, {2, 30, 1}}, "America/New_York")
      sunday_end = DT.from_erl!({{2017, 6, 5}, {2, 30, 0}}, "America/New_York")

      assert DTH.next_weekend(@thursday) == {saturday_start, sunday_end}
    end

    test "future/0" do
      monday_start = DT.from_erl!({{2017, 6, 5}, {2, 30, 1}}, "America/New_York")
      far_in_future = DT.from_erl!({{3000, 01, 01}, {0, 0, 0}}, "America/New_York")

      assert DTH.future(@thursday) == {monday_start, far_in_future}
    end
  end

  describe "format_date" do
    test "returns date in m-d-Y format in provided timezone" do
      assert DTH.format_date(~N[2017-08-28 12:00:00], "America/New_York") == "08-28-2017"
    end

    test "returns date in m-d-Y format defaulting to Amerca/New_York" do
      assert DTH.format_date(~N[2017-08-28 12:00:00]) == "08-28-2017"
    end

    test "returns date in m-d-Y format and adjusts date based on timezone" do
      assert DTH.format_date(~N[2017-08-28 02:00:00]) == "08-27-2017"
    end
  end

  describe "determine_relevant_day_of_week" do
    test "handles weekday" do
      friday = DT.from_erl!({{2017, 10, 13}, {12, 0, 0}}, "Etc/UTC")
      assert :weekday = DTH.determine_relevant_day_of_week(friday)
    end

    test "handles weekday early morning" do
      friday = DT.from_erl!({{2017, 10, 13}, {6, 0, 0}}, "Etc/UTC")
      assert :weekday = DTH.determine_relevant_day_of_week(friday)
    end

    test "handles monday early morning" do
      monday = DT.from_erl!({{2017, 10, 9}, {6, 0, 0}}, "Etc/UTC")
      assert :sunday = DTH.determine_relevant_day_of_week(monday)
    end

    test "handles saturday" do
      saturday = DT.from_erl!({{2017, 10, 14}, {12, 0, 0}}, "Etc/UTC")
      assert :saturday = DTH.determine_relevant_day_of_week(saturday)
    end

    test "handles saturday early morning" do
      saturday = DT.from_erl!({{2017, 10, 14}, {6, 30, 0}}, "Etc/UTC")
      assert :weekday = DTH.determine_relevant_day_of_week(saturday)
    end

    test "handles sunday" do
      sunday = DT.from_erl!({{2017, 10, 15}, {12, 0, 0}}, "Etc/UTC")
      assert :sunday = DTH.determine_relevant_day_of_week(sunday)
    end

    test "handles sunday early morning" do
      sunday = DT.from_erl!({{2017, 10, 15}, {5, 30, 0}}, "Etc/UTC")
      assert :saturday = DTH.determine_relevant_day_of_week(sunday)
    end
  end

  describe "parse_unix_timestamp/2" do
    test "parses a unix timestamp with the default time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1500306651)
      assert datetime == DT.from_erl!({{2017, 7, 17}, {11, 50, 51}}, "America/New_York")
    end

    test "parses a unix timestamp with the given time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1500306651, "Etc/UTC")
      assert datetime == DT.from_erl!({{2017, 7, 17}, {15, 50, 51}}, "Etc/UTC")
    end

    test "returns :error when the timestamp can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(-218937198213123)
    end

    test "returns :error when the given time zone can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(1500306651, "not a time zone")
    end
  end
end
