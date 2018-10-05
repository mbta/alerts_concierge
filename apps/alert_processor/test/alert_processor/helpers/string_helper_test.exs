defmodule AlertProcessor.Helpers.StringHelperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.Helpers.StringHelper

  test "capitalize_first/1 capitalizes the first character of a string and does not change the remaining characters" do
    capitalized = StringHelper.capitalize_first("every Monday from 3 to 5 PM")

    assert capitalized == "Every Monday from 3 to 5 PM"
  end

  describe "or_join" do
    test "handles empty list" do
      assert "" == StringHelper.or_join([])
    end

    test "handles one item list" do
      assert "one" == StringHelper.or_join(["one"])
    end

    test "handles two item list" do
      assert "one or two" == StringHelper.or_join(["one", "two"])
    end

    test "handles three or more item list" do
      assert "one, two, or three" == StringHelper.or_join(["one", "two", "three"])
    end
  end

  describe "and_join" do
    test "handles empty list" do
      assert "" == StringHelper.and_join([])
    end

    test "handles one item list" do
      assert "one" == StringHelper.and_join(["one"])
    end

    test "handles two item list" do
      assert "one and two" == StringHelper.and_join(["one", "two"])
    end

    test "handles three or more item list" do
      assert "one, two, and three" == StringHelper.and_join(["one", "two", "three"])
    end
  end
end
