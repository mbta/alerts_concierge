defmodule ConciergeSite.DaySelectHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.DaySelectHelper

  test "render/1" do
    html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo))

    assert html =~ "<div class=\"day-selector\" data-selector=\"date\">"
    assert html =~ "<div class=\"day-header\">Mon</div>"
    assert html =~ "<input autocomplete=\"off\" name=\"foo[days][]\" type=\"checkbox\" value=\"monday\">"
    assert html =~ "<div class=\"group-part invisible-no-js\">"
    assert html =~ "<input autocomplete=\"off\" type=\"checkbox\" value=\"weekdays\">"
  end
end
