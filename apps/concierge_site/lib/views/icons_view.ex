defmodule ConciergeSite.IconsView do
  use ConciergeSite.Web, :view

  def render("_circle_icon.html", %{route: route, large: true}) do
    downcase_route_name = route |> String.split() |> List.first() |> String.downcase()

    render "_circle_icon.html", %{svg_class: "large-icon-with-circle", title: route, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end

  def render("_circle_icon.html", %{route: route}) do
    downcase_route_name = route |> String.split() |> List.first() |> String.downcase()

    render "_circle_icon.html", %{svg_class: "icon-with-circle", title: route, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end
end
