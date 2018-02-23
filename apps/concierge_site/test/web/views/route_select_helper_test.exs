defmodule ConciergeSite.RouteSelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.RouteSelectHelper

  test "render/2" do
    html = Phoenix.HTML.safe_to_string(RouteSelectHelper.render(:foo, :bar))

    assert html =~ "<select class=\"form-control\" data-type=\"route\" id=\"foo_bar\" name=\"foo[bar]\">"
    assert html =~ "Select a subway, commuter rail, ferry or bus route"
    assert html =~ "<optgroup label=\"Subway\">"
    assert html =~ "<option data-icon=\"orange\" value=\"Orange\">"
    assert html =~ "Red Line"
    assert html =~ "CR-Franklin"
    assert html =~ "Hingham/Hull Ferry"
    assert html =~ "Route 5 - City Point - Outbound"
    assert html =~ "data-type=\"route\""
    assert html =~ "data-icon=\"cr\""
  end
end
