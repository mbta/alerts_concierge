defmodule AlertProcessor.Helpers.DateTimeHelperTest do
  use ExUnit.Case
  alias AlertProcessor.Helpers.DateTimeHelper, as: DTH
  alias Calendar.DateTime, as: DT

  test "time_without_zone/1" do
    assert ~T[12:10:00.000] = DTH.time_without_zone("2015-01-23T12:10:00.000+02:30")
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

  describe "format_time" do
    test "returns time in %l:%M%P format in provided timezone" do
      assert DTH.format_time(~N[2017-08-28 12:00:00], "America/New_York") == " 8:00am"
    end

    test "returns time in %l:%M%P format defaulting to Amerca/New_York" do
      assert DTH.format_time(~N[2017-08-28 12:00:00]) == " 8:00am"
    end

    test "returns time in %l:%M%P format and adjusts time based on timezone" do
      assert DTH.format_time(~N[2017-08-28 02:00:00]) == "10:00pm"
    end
  end

  describe "within_relevant_day_of_week?" do
    test "handles weekday" do
      friday = DT.from_erl!({{2017, 10, 13}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:weekday], friday)
      refute DTH.within_relevant_day_of_week?([:saturday], friday)
    end

    test "handles weekday early morning" do
      friday = DT.from_erl!({{2017, 10, 13}, {6, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:weekday], friday)
      refute DTH.within_relevant_day_of_week?([:saturday], friday)
    end

    test "handles weekend early morning" do
      saturday = DT.from_erl!({{2017, 10, 14}, {6, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:weekday], saturday)
      refute DTH.within_relevant_day_of_week?([:saturday], saturday)
    end

    test "handles monday" do
      monday = DT.from_erl!({{2017, 10, 9}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:monday], monday)
      refute DTH.within_relevant_day_of_week?([:sunday], monday)
    end

    test "handles tuesday" do
      tuesday = DT.from_erl!({{2017, 10, 10}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:tuesday], tuesday)
      refute DTH.within_relevant_day_of_week?([:monday], tuesday)
    end

    test "handles wednesday" do
      wednesday = DT.from_erl!({{2017, 10, 11}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:wednesday], wednesday)
      refute DTH.within_relevant_day_of_week?([:tuesday], wednesday)
    end

    test "handles thursday" do
      thursday = DT.from_erl!({{2017, 10, 12}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:thursday], thursday)
      refute DTH.within_relevant_day_of_week?([:wednesday], thursday)
    end

    test "handles friday" do
      friday = DT.from_erl!({{2017, 10, 13}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:friday], friday)
      refute DTH.within_relevant_day_of_week?([:thursday], friday)
    end

    test "handles saturday" do
      saturday = DT.from_erl!({{2017, 10, 14}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:saturday], saturday)
      refute DTH.within_relevant_day_of_week?([:friday], saturday)
    end

    test "handles sunday" do
      sunday = DT.from_erl!({{2017, 10, 15}, {12, 0, 0}}, "Etc/UTC")
      assert DTH.within_relevant_day_of_week?([:sunday], sunday)
      refute DTH.within_relevant_day_of_week?([:saturday], sunday)
    end

    test "handles monday early morning" do
      monday = DT.from_erl!({{2017, 10, 9}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:monday], monday)
      assert DTH.within_relevant_day_of_week?([:sunday], monday)
    end

    test "handles tuesday early morning" do
      tuesday = DT.from_erl!({{2017, 10, 10}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:tuesday], tuesday)
      assert DTH.within_relevant_day_of_week?([:monday], tuesday)
    end

    test "handles wednesday early morning" do
      wednesday = DT.from_erl!({{2017, 10, 11}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:wednesday], wednesday)
      assert DTH.within_relevant_day_of_week?([:tuesday], wednesday)
    end

    test "handles thursday early morning" do
      thursday = DT.from_erl!({{2017, 10, 12}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:thursday], thursday)
      assert DTH.within_relevant_day_of_week?([:wednesday], thursday)
    end

    test "handles friday early morning" do
      friday = DT.from_erl!({{2017, 10, 13}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:friday], friday)
      assert DTH.within_relevant_day_of_week?([:thursday], friday)
    end

    test "handles saturday early morning" do
      saturday = DT.from_erl!({{2017, 10, 14}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:saturday], saturday)
      assert DTH.within_relevant_day_of_week?([:friday], saturday)
    end

    test "handles sunday early morning" do
      sunday = DT.from_erl!({{2017, 10, 15}, {6, 0, 0}}, "Etc/UTC")
      refute DTH.within_relevant_day_of_week?([:sunday], sunday)
      assert DTH.within_relevant_day_of_week?([:saturday], sunday)
    end
  end

  describe "parse_unix_timestamp/2" do
    test "parses a unix timestamp with the default time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1_500_306_651)
      assert datetime == DT.from_erl!({{2017, 7, 17}, {11, 50, 51}}, "America/New_York")
    end

    test "parses a unix timestamp with the given time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1_500_306_651, "Etc/UTC")
      assert datetime == DT.from_erl!({{2017, 7, 17}, {15, 50, 51}}, "Etc/UTC")
    end

    test "returns :error when the timestamp can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(-218_937_198_213_123)
    end

    test "returns :error when the given time zone can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(1_500_306_651, "not a time zone")
    end
  end

  describe "datetime_to_local/2" do
    test "UTC time accurately converted to localtime" do
      assert DT.from_erl!({{2017, 10, 13}, {8, 0, 0}}, "America/New_York") ==
               DTH.datetime_to_local(DT.from_erl!({{2017, 10, 13}, {12, 0, 0}}, "Etc/UTC"))
    end
  end

  describe "time_to_local_datetime/2" do
    test "time accurated converted to a local DateTime relative to the day provided" do
      assert DT.from_erl!({{2017, 10, 13}, {9, 0, 0}}, "America/New_York") ==
               DTH.time_to_local_datetime(
                 Time.from_erl!({9, 0, 0}),
                 DT.from_erl!({{2017, 10, 13}, {12, 0, 0}}, "Etc/UTC")
               )
    end
  end
end
