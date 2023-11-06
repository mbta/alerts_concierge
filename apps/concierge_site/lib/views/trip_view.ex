defmodule ConciergeSite.TripView do
  use ConciergeSite.Web, :view

  alias alias AlertProcessor.Model.Trip
  alias Plug.Conn

  @spec route_names_for_alternate_routes(list(String.t())) :: String.t()
  def route_names_for_alternate_routes(alternate_routes) do
    [last_route | routes] = Enum.reverse(alternate_routes)
    [_, last_route_name, _] = String.split(last_route, "~~")
    routes = Enum.reverse(routes)

    route_names =
      Enum.map_join(routes, ", ", fn leg ->
        [_, route_name, _] = String.split(leg, "~~")
        route_name
      end)

    if route_names == "", do: last_route_name, else: "#{route_names} and #{last_route_name}"
  end

  @spec subscription_deleted_message :: String.t()
  def subscription_deleted_message, do: "Subscription deleted."

  @spec show_deleted_last_trip_survey?(Conn.t(), [Trip.t()]) :: boolean()
  def show_deleted_last_trip_survey?(conn, trips),
    do: get_flash(conn, :info) == subscription_deleted_message() and Enum.empty?(trips)
end
