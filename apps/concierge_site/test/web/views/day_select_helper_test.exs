defmodule ConciergeSite.DaySelectHelperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ConciergeSite.DaySelectHelper

  test "render/1" do
    html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo))

    assert html =~ "<div class=\"day-selector\" data-selector=\"date\">"
    assert html =~ "<div class=\"day-header\">Mon</div>"

    assert html =~
             "<input autocomplete=\"off\" name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"monday\">"

    assert html =~
             "<input autocomplete=\"off\" name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"tuesday\">"

    assert html =~ "<div class=\"group-part invisible-no-js\">"
    assert html =~ "<input autocomplete=\"off\" type=\"checkbox\" value=\"weekdays\">"
  end

  describe "render/2" do
    test "with monday as string" do
      html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo, ["monday"]))

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"monday\">"

      assert html =~
               "<input autocomplete=\"off\" name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"tuesday\">"
    end

    test "with monday as atom" do
      html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo, [:monday]))

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"monday\">"

      assert html =~
               "<input autocomplete=\"off\" name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"tuesday\">"
    end

    test "weekdays" do
      weekdays = ~w(monday tuesday wednesday thursday friday)a
      html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo, weekdays))

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"monday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"tuesday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"thursday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"friday\">"

      assert html =~ "<input autocomplete=\"off\" checked type=\"checkbox\" value=\"weekdays\">"
    end

    test "weekend" do
      weekdays = ~w(saturday sunday)a
      html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo, weekdays))

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"saturday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

      assert html =~ "<input autocomplete=\"off\" checked type=\"checkbox\" value=\"weekend\">"
    end

    test "weekdays and weekend" do
      weekdays = ~w(monday tuesday wednesday thursday friday saturday sunday)a
      html = Phoenix.HTML.safe_to_string(DaySelectHelper.render(:foo, weekdays))

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"monday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"tuesday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"thursday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"friday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"saturday\">"

      assert html =~
               "<input autocomplete=\"off\" checked name=\"foo[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

      assert html =~ "<input autocomplete=\"off\" checked type=\"checkbox\" value=\"weekdays\">"
      assert html =~ "<input autocomplete=\"off\" checked type=\"checkbox\" value=\"weekend\">"
    end
  end
end
