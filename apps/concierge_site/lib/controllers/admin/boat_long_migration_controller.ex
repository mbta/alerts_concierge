defmodule ConciergeSite.Admin.BoatLongMigrationController do
  use ConciergeSite.Web, :controller

  import Ecto.Query

  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo

  def index(conn, _params) do
    boat_f1_boat_long_count = subscription_count_for_route_and_stop("Boat-F1", "Boat-Long")

    boat_eastboston_boat_long_count =
      subscription_count_for_route_and_stop("Boat-EastBoston", "Boat-Long")

    boat_eastboston_boat_long_north_5b_count =
      subscription_count_for_route_and_stop("Boat-EastBoston", "Boat-Long-North-5B")

    boat_lynn_boat_long_count = subscription_count_for_route_and_stop("Boat-Lynn", "Boat-Long")

    boat_lynn_boat_long_north_5c_count =
      subscription_count_for_route_and_stop("Boat-Lynn", "Boat-Long-North-5C")

    render(conn, "index.html",
      boat_f1_boat_long_count: boat_f1_boat_long_count,
      boat_eastboston_boat_long_count: boat_eastboston_boat_long_count,
      boat_eastboston_boat_long_north_5b_count: boat_eastboston_boat_long_north_5b_count,
      boat_lynn_boat_long_count: boat_lynn_boat_long_count,
      boat_lynn_boat_long_north_5c_count: boat_lynn_boat_long_north_5c_count
    )
  end

  defp subscription_count_for_route_and_stop(route, stop) do
    Repo.one(
      from(s in Subscription,
        where: s.route == ^route and (s.origin == ^stop or s.destination == ^stop),
        select: count(s.id)
      )
    )
  end
end
