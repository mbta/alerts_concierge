defmodule ConciergeSite.IconViewHelperTest do
  use ExUnit.Case
  alias ConciergeSite.IconViewHelper

  test "icon/1 returns raw code for an svg" do
    {:safe, html} = IconViewHelper.icon(:red)
    assert html =~ "<svg"
  end

  test "icon_for_route/2 returns raw code for an svg given a route" do
    {:safe, html} = IconViewHelper.icon_for_route(:cr, "CR-Worcester")
    assert html =~ "<svg"
  end
end
