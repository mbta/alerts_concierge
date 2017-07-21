defmodule AlertProcessor.Model.RouteTest do
  use ExUnit.Case

  alias AlertProcessor.Model.Route

  describe "name/2" do
    test "uses preferred name if present" do
      route = %Route{long_name: "Test", short_name: "T"}

      assert Route.name(route) == "Test"
      assert Route.name(route, :long_name) == "Test"
      assert Route.name(route, :short_name) == "T"
    end

    test "uses inverse if name not present" do
      route = %Route{long_name: "Test", short_name: ""}

      assert Route.name(route, :short_name) == "Test"
    end
  end
end
