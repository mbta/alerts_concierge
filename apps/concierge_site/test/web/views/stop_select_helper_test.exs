defmodule ConciergeSite.StopSelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.StopSelectHelper

  test "render/3 Subway Line" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Red", :foo, :bar))

    assert html =~ "<select class=\"form-control\" data-route=\"Red\" data-type=\"stop-choices\" id=\"foo_bar\" name=\"foo[bar]\">"
    assert html =~ "Select a stop"
    assert html =~ "<option data-bus=\"true\" data-mattapan=\"true\" data-red=\"true\" data-red-1=\"true\" value=\"place-asmnl\">Ashmont</option>"
    assert html =~ "<option data-green-b=\"true\" data-green-c=\"true\" data-green-d=\"true\" data-green-e=\"true\" data-red=\"true\" data-red-1=\"true\" data-red-2=\"true\" value=\"place-pktrm\">Park Street</option>"
    assert html =~ "<option data-orange=\"true\" data-red=\"true\" data-red-1=\"true\" data-red-2=\"true\" value=\"place-dwnxg\">Downtown Crossing</option>"
    assert html =~ "<option data-bus=\"true\" data-cr=\"true\" data-red=\"true\" data-red-2=\"true\" value=\"place-brntn\">Braintree</option>"
  end

  test "render/3 Commuter Rail" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("CR-Haverhill", :foo, :bar))

    assert html =~ "<option data-bus=\"true\" data-cr=\"true\" data-orange=\"true\" value=\"place-mlmnl\">Malden Center</option>"
  end

  test "render/3 Mattapan" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Mattapan", :foo, :bar))

    assert html =~ "<option data-bus=\"true\" data-mattapan=\"true\" data-red=\"true\" value=\"place-asmnl\">Ashmont</option>"
  end

  test "render/3 Ferry" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Boat-F4", :foo, :bar))

    assert html =~ "<option data-ferry=\"true\" value=\"Boat-Charlestown\">Charlestown</option>"
  end

  test "render/3 Green-B" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Green-B", :foo, :bar))

    assert html =~ "<option data-green-b=\"true\" data-green-c=\"true\" data-green-d=\"true\" data-green-e=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
  end

  test "render/3 Green-C" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Green-C", :foo, :bar))

    assert html =~ "<option data-green-b=\"true\" data-green-c=\"true\" data-green-d=\"true\" data-green-e=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
  end

  test "render/3 Green-D" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Green-D", :foo, :bar))

    assert html =~ "<option data-green-b=\"true\" data-green-c=\"true\" data-green-d=\"true\" data-green-e=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
  end

  test "render/3 Green-E" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Green-E", :foo, :bar))

    assert html =~ "<option data-green-b=\"true\" data-green-c=\"true\" data-green-d=\"true\" data-green-e=\"true\" data-red=\"true\" value=\"place-pktrm\">Park Street</option>"
  end

  test "render/4 Orange with pre-selection" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Orange", :foo, :bar, ["place-ogmnl"]))

    assert html =~ "<option data-bus=\"true\" data-orange=\"true\" selected=\"selected\" value=\"place-ogmnl\">Oak Grove</option>"
  end

  test "render/5 Orange with multiple and no default" do
    html = Phoenix.HTML.safe_to_string(StopSelectHelper.render("Orange", :foo, :bar, [], [no_default: true,
                                                                                          multiple: "multiple"]))

    refute html =~ "<option disabled=\"disabled\" selected=\"selected\" value=\"\">Select a stop</option>"
    assert html =~ "<select class=\"form-control\" data-route=\"Orange\" data-type=\"stop-choices\" id=\"foo_bar\" multiple=\"multiple\" name=\"foo[bar][]\""
  end
end
