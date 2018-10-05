defmodule AlertProcessor.Model.RouteTest do
  @moduledoc false
  use ExUnit.Case, async: true

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

  describe "bus_short_name/1" do
    test "adds 'Silver Line' to the front if the short name starts with 'SL'" do
      sl_route = %Route{short_name: "SL5"}

      assert Route.bus_short_name(sl_route) == "Silver Line SL5"
    end

    test "adds 'Route' to the front of the short name otherwise" do
      ct_route = %Route{short_name: "CT1"}
      number_route = %Route{short_name: "7"}

      assert Route.bus_short_name(ct_route) == "Route CT1"
      assert Route.bus_short_name(number_route) == "Route 7"
    end
  end
end
