defmodule ConciergeSite.RouteSelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.RouteSelectHelper

  test "render/2" do
    html = Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar))

    assert html =~
             "<select class=\"form-control\" data-type=\"route\" id=\"foo_bar\" name=\"foo[bar]\">"

    assert html =~ "Select a subway, commuter rail, ferry or bus route"
    assert html =~ "<optgroup label=\"Subway\">"
    assert html =~ "<option data-icon=\"orange\" value=\"Orange~~Orange Line~~subway\">"
    assert html =~ "Red Line"
    assert html =~ "CR-Franklin"
    assert html =~ "Hingham/Hull Ferry"
    assert html =~ "Route 5 - City Point - Outbound"
    assert html =~ "data-type=\"route\""
    assert html =~ "data-icon=\"cr\""
  end

  test "render/3" do
    html =
      Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar, ["Red~~Red Line~~subway"]))

    assert html =~
             "<option data-icon=\"red\" selected=\"selected\" value=\"Red~~Red Line~~subway\">Red Line</option>"
  end

  describe "render/4" do
    test "select multiple" do
      html =
        Phoenix.HTML.safe_to_string(
          RouteSelectHelper.render(
            :foo,
            :bar,
            [],
            class: "some-other-class",
            no_default: true,
            multiple: "multiple"
          )
        )

      assert html =~ "Silver Line SL5"

      assert html =~
               "<select class=\"some-other-class\" data-type=\"route\" id=\"foo_bar\" multiple=\"multiple\" name=\"foo[bar][]\""

      refute html =~
               "<option disabled=\"disabled\" selected=\"selected\" value=\"\">Select a subway, commuter rail, ferry or bus route</option>"
    end

    test "no buses" do
      html =
        Phoenix.HTML.safe_to_string(
          RouteSelectHelper.render(:foo, :bar, [], no_default: true, no_bus: true)
        )

      refute html =~ "Silver Line SL5"
    end

    test "collapsed Green Line" do
      html =
        Phoenix.HTML.safe_to_string(
          ConciergeSite.RouteSelectHelper.render(
            :foo,
            :bar,
            [],
            multiple: "multiple",
            no_default: true
          )
        )

      assert html =~
               "<option data-icon=\"green\" value=\"Green~~Green Line~~subway\">Green Line</option>"

      refute html =~
               "<option data-icon=\"green-b\" value=\"Green-B~~Green Line B~~subway_all_green\">Green Line B</option>"
    end

    test "expanded Green Line" do
      html =
        Phoenix.HTML.safe_to_string(
          ConciergeSite.RouteSelectHelper.render(
            :foo,
            :bar,
            [],
            multiple: "multiple",
            no_default: true,
            separate_green: true
          )
        )

      assert html =~
               "<option data-icon=\"green-b\" value=\"Green-B~~Green Line B~~subway_all_green\">Green Line B</option>"

      refute html =~
               "<option data-icon=\"green\" value=\"Green~~Green Line~~subway\">Green Line</option>"
    end
  end
end
