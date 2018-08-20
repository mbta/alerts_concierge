defmodule ConciergeSite.TimeHelperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ConciergeSite.TimeHelper

  describe "format_time/1" do
    test "converts time into readable format" do
      actual = TimeHelper.format_time(~T[01:00:00.000000])
      expected = " 1:00 AM"
      assert actual == expected
    end

    test "converts nil to empty string" do
      actual = TimeHelper.format_time(nil)
      expected = ""
      assert actual == expected
    end

    test "optionally strips leading zero" do
      assert TimeHelper.format_time(~T[14:00:00], "%l") == " 2"
      assert TimeHelper.format_time(~T[14:00:00], "%I", true) == "2"
    end
  end

  describe "format_time_string/1" do
    test "takes a time string in format HH:MM:SS and returns HH:MM AM/PM, zero-padded" do
      assert TimeHelper.format_time_string("14:00:00") == "02:00 PM"
    end
  end

  describe "time_to_string/1" do
    test "Converts a Time.t to a string with the H:M:S format" do
      assert TimeHelper.time_to_string(~T[14:00:00]) == "14:00:00"
    end

    test "returns nil when given nil" do
      assert TimeHelper.time_to_string(nil) == nil
    end
  end
end
