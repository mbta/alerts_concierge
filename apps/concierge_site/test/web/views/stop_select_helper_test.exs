defmodule ConciergeSite.StopSelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.StopSelectHelper

  test "render/3 Subway Line" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Red", :foo, :bar))

    assert html =~ "<select class=\"form-control\" data-type=\"stop\" id=\"foo_bar\" name=\"foo[bar]\">"
    assert html =~ "Select a stop"
    assert html =~ "<option data-accessible=\"true\" data-bus=\"true\" data-mattapan=\"true\" data-red=\"true\" value=\"place-asmnl\">Ashmont</option>"
    assert html =~ "<option data-accessible=\"true\" data-green=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
    assert html =~ "<option data-accessible=\"true\" data-orange=\"true\" data-red=\"true\" value=\"place-dwnxg\">Downtown Crossing</option>"
  end

  test "render/3 Commuter Rail" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("CR-Haverhill", :foo, :bar))

    assert html =~ "<option data-accessible=\"true\" data-bus=\"true\" data-cr=\"true\" data-orange=\"true\" value=\"place-mlmnl\">Malden Center</option>"
  end

  test "render/3 Mattapan" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Mattapan", :foo, :bar))

    assert html =~ "<option data-accessible=\"true\" data-bus=\"true\" data-mattapan=\"true\" data-red=\"true\" value=\"place-asmnl\">Ashmont</option>"
  end

  test "render/3 Ferry" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Boat-F4", :foo, :bar))

    assert html =~ "<option data-accessible=\"true\" data-ferry=\"true\" value=\"Boat-Charlestown\">Charlestown</option>"
  end

  test "render/3 Green" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Green", :foo, :bar))

    assert html =~ "<option data-accessible=\"true\" data-green=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
  end
end
