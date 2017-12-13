defmodule ConciergeSite.TimeHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias AlertProcessor.Model.{Subscription, User}
  alias ConciergeSite.TimeHelper

  test "string_to_time/1" do
    assert nil == TimeHelper.string_to_time(nil)
    assert ~T[04:00:00] == TimeHelper.string_to_time("04:00:00")
  end

  test "travel_time_options/0 returns list of formatted 15 min increments" do
    expected = [
    {"03:00 AM", "03:00:00"}, {"03:15 AM", "03:15:00"},
    {"03:30 AM", "03:30:00"}, {"03:45 AM", "03:45:00"}, {"04:00 AM", "04:00:00"},
    {"04:15 AM", "04:15:00"}, {"04:30 AM", "04:30:00"}, {"04:45 AM", "04:45:00"},
    {"05:00 AM", "05:00:00"}, {"05:15 AM", "05:15:00"}, {"05:30 AM", "05:30:00"},
    {"05:45 AM", "05:45:00"}, {"06:00 AM", "06:00:00"}, {"06:15 AM", "06:15:00"},
    {"06:30 AM", "06:30:00"}, {"06:45 AM", "06:45:00"}, {"07:00 AM", "07:00:00"},
    {"07:15 AM", "07:15:00"}, {"07:30 AM", "07:30:00"}, {"07:45 AM", "07:45:00"},
    {"08:00 AM", "08:00:00"}, {"08:15 AM", "08:15:00"}, {"08:30 AM", "08:30:00"},
    {"08:45 AM", "08:45:00"}, {"09:00 AM", "09:00:00"}, {"09:15 AM", "09:15:00"},
    {"09:30 AM", "09:30:00"}, {"09:45 AM", "09:45:00"}, {"10:00 AM", "10:00:00"},
    {"10:15 AM", "10:15:00"}, {"10:30 AM", "10:30:00"}, {"10:45 AM", "10:45:00"},
    {"11:00 AM", "11:00:00"}, {"11:15 AM", "11:15:00"}, {"11:30 AM", "11:30:00"},
    {"11:45 AM", "11:45:00"}, {"12:00 PM", "12:00:00"}, {"12:15 PM", "12:15:00"},
    {"12:30 PM", "12:30:00"}, {"12:45 PM", "12:45:00"}, {"01:00 PM", "13:00:00"},
    {"01:15 PM", "13:15:00"}, {"01:30 PM", "13:30:00"}, {"01:45 PM", "13:45:00"},
    {"02:00 PM", "14:00:00"}, {"02:15 PM", "14:15:00"}, {"02:30 PM", "14:30:00"},
    {"02:45 PM", "14:45:00"}, {"03:00 PM", "15:00:00"}, {"03:15 PM", "15:15:00"},
    {"03:30 PM", "15:30:00"}, {"03:45 PM", "15:45:00"}, {"04:00 PM", "16:00:00"},
    {"04:15 PM", "16:15:00"}, {"04:30 PM", "16:30:00"}, {"04:45 PM", "16:45:00"},
    {"05:00 PM", "17:00:00"}, {"05:15 PM", "17:15:00"}, {"05:30 PM", "17:30:00"},
    {"05:45 PM", "17:45:00"}, {"06:00 PM", "18:00:00"}, {"06:15 PM", "18:15:00"},
    {"06:30 PM", "18:30:00"}, {"06:45 PM", "18:45:00"}, {"07:00 PM", "19:00:00"},
    {"07:15 PM", "19:15:00"}, {"07:30 PM", "19:30:00"}, {"07:45 PM", "19:45:00"},
    {"08:00 PM", "20:00:00"}, {"08:15 PM", "20:15:00"}, {"08:30 PM", "20:30:00"},
    {"08:45 PM", "20:45:00"}, {"09:00 PM", "21:00:00"}, {"09:15 PM", "21:15:00"},
    {"09:30 PM", "21:30:00"}, {"09:45 PM", "21:45:00"}, {"10:00 PM", "22:00:00"},
    {"10:15 PM", "22:15:00"}, {"10:30 PM", "22:30:00"}, {"10:45 PM", "22:45:00"},
    {"11:00 PM", "23:00:00"}, {"11:15 PM", "23:15:00"}, {"11:30 PM", "23:30:00"},
    {"11:45 PM", "23:45:00"}, {"12:00 AM", "00:00:00"}, {"12:15 AM", "00:15:00"},
    {"12:30 AM", "00:30:00"}, {"12:45 AM", "00:45:00"}, {"01:00 AM", "01:00:00"},
    {"01:15 AM", "01:15:00"}, {"01:30 AM", "01:30:00"}, {"01:45 AM", "01:45:00"},
    {"02:00 AM", "02:00:00"}, {"02:15 AM", "02:15:00"}, {"02:30 AM", "02:30:00"},
    {"02:45 AM", "02:45:00"}
    ]

    assert TimeHelper.travel_time_options() == expected
  end

  describe "subscription_during_do_not_disturb?/2" do
    test "returns true if range is completely contained within other" do
      assert TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[05:00:00], end_time: ~T[06:00:00]}, %User{do_not_disturb_start: ~T[05:00:00], do_not_disturb_end: ~T[07:00:00]})
    end

    test "returns true if range is partially contained within other" do
      assert TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[08:00:00], end_time: ~T[12:00:00]}, %User{do_not_disturb_start: ~T[05:00:00], do_not_disturb_end: ~T[14:00:00]})
    end

    test "returns false if no overlap" do
      refute TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[15:00:00], end_time: ~T[17:00:00]}, %User{do_not_disturb_start: ~T[09:00:00], do_not_disturb_end: ~T[14:00:00]})
    end

    test "handles overnight dnd periods" do
      assert TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[18:00:00], end_time: ~T[22:00:00]}, %User{do_not_disturb_start: ~T[17:00:00], do_not_disturb_end: ~T[02:00:00]})
    end

    test "handles overnight dnd periods with subscription in the morning" do
      assert TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[16:00:00], end_time: ~T[18:00:00]}, %User{do_not_disturb_start: ~T[17:00:00], do_not_disturb_end: ~T[08:00:00]})
    end

    test "returns false if dnd period is not set" do
      refute TimeHelper.subscription_during_do_not_disturb?(%Subscription{start_time: ~T[17:00:00], end_time: ~T[23:00:00]}, %User{do_not_disturb_start: nil, do_not_disturb_end: nil})
    end
  end
end
