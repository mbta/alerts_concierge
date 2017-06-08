defmodule ConciergeSite.IconsViewTest do
  use ExUnit.Case, async: true

  import Phoenix.View

  alias AlertProcessor.Model.Route

  test "renders icon partial" do
    rendered_template = render_to_string(ConciergeSite.IconsView, "_circle_icon.html", %{route: %Route{long_name: "Green Line B"}})
    assert rendered_template =~ ~s(title="Green Line B")
    assert rendered_template =~ ~s(class="icon-green-line-circle")
    assert rendered_template =~ ~s(class="icon-with-circle")
  end

  test "renders large icon partial" do
    rendered_template = render_to_string(ConciergeSite.IconsView, "_circle_icon.html", %{route: %Route{long_name: "Red Line"}, large: true})
    assert rendered_template =~ ~s(title="Red Line")
    assert rendered_template =~ ~s(class="icon-red-line-circle")
    assert rendered_template =~ ~s(class="large-icon-with-circle")
  end
end
