defmodule ConciergeSite.TimeHelperTest do
  @moduledoc false
  use ExUnit.Case
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
  end
end
