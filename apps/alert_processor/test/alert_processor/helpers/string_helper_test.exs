defmodule AlertProcessor.Helpers.StringHelperTest do
  use ExUnit.Case
  alias AlertProcessor.Helpers.StringHelper

  test "capitalize_first/1 capitalizes the first character of a string and does not change the remaining characters" do
    capitalized = StringHelper.capitalize_first("every Monday from 3 to 5 PM")

    assert capitalized == "Every Monday from 3 to 5 PM"
  end
end
