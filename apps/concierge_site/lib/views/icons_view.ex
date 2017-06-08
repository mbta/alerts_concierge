defmodule ConciergeSite.IconsView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.Route

  def render("_circle_icon.html", %{route: %Route{long_name: long_name}, large: true}) do
    downcase_route_name = long_name |> String.split() |> List.first() |> String.downcase()

    render "_circle_icon.html", %{svg_class: "large-icon-with-circle", title: long_name, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end

  def render("_circle_icon.html", %{route: %Route{long_name: long_name}}) do
    downcase_route_name = long_name |> String.split() |> List.first() |> String.downcase()

    render "_circle_icon.html", %{svg_class: "icon-with-circle", title: long_name, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end
end
