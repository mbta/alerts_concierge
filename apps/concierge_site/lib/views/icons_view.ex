defmodule ConciergeSite.IconsView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.Route

  def render("_circle_icon.html", %{route: route, large: true}) do
    route_name = Route.name(route)
    downcase_route_name = route_name
      |> String.split()
      |> List.first()
      |> String.downcase()

    render "_circle_icon.html", %{svg_class: "large-icon-with-circle", title: route_name, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end

  def render("_circle_icon.html", %{route: route}) do
    route_name = Route.name(route)
    downcase_route_name = route_name
      |> String.split()
      |> List.first()
      |> String.downcase()

    render "_circle_icon.html", %{svg_class: "icon-with-circle", title: route_name, circle_class: ["icon-", downcase_route_name, "-line-circle"]}
  end
end
