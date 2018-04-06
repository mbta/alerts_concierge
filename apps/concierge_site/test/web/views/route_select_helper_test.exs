defmodule ConciergeSite.RouteSelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.RouteSelectHelper

  test "render/2" do
    html = Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar))

    assert html =~ "<select class=\"form-control\" data-type=\"route\" id=\"foo_bar\" name=\"foo[bar]\">"
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
    html = Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar, ["Red~~Red Line~~subway"]))

    assert html =~ "<option data-icon=\"red\" selected=\"selected\" value=\"Red~~Red Line~~subway\">Red Line</option>"
  end

  test "render/4" do
    html = Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar, [], [class: "some-other-class",
                                                                                 no_default: true,
                                                                                 multiple: "multiple"]))

    assert html =~ "<select class=\"some-other-class\" data-type=\"route\" id=\"foo_bar\" multiple=\"multiple\" name=\"foo[bar][]\""
    refute html =~ "<option disabled=\"disabled\" selected=\"selected\" value=\"\">Select a subway, commuter rail, ferry or bus route</option>"
  end
end
