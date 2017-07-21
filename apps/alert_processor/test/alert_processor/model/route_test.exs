defmodule AlertProcessor.Model.RouteTest do
  use ExUnit.Case

  alias AlertProcessor.Model.Route

  describe "name/1" do
    test "uses long name if present" do
      route = %Route{long_name: "Test"}
      assert Route.name(route) == "Test"
    end

    test "uses short_name if long name not present" do
      route = %Route{long_name: "", short_name: "Test"}
      assert Route.name(route) == "Test"
    end
  end
end
