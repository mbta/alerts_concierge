defmodule ConciergeSite.Admin.BoatLongMigrationController do
  use ConciergeSite.Web, :controller

  import Ecto.Query

  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo

  @f1_route "Boat-F1"
  @f1_stop "Boat-Long"

  @eastboston_route "Boat-EastBoston"
  @eastboston_old_stop "Boat-Long"
  @eastboston_new_stop "Boat-Long-North-5B"

  @lynn_route "Boat-Lynn"
  @lynn_old_stop "Boat-Long"
  @lynn_new_stop "Boat-Long-North-5C"

  def index(conn, _params) do
    f1_count = subscription_count_for_route_and_stop(@f1_route, @f1_stop)

    eastboston_old_stop_count =
      subscription_count_for_route_and_stop(@eastboston_route, @eastboston_old_stop)

    eastboston_new_stop_count =
      subscription_count_for_route_and_stop(@eastboston_route, @eastboston_new_stop)

    lynn_old_stop_count = subscription_count_for_route_and_stop(@lynn_route, @lynn_old_stop)

    lynn_new_stop_count =
      subscription_count_for_route_and_stop(@lynn_route, @lynn_new_stop)

    render(conn, "index.html",
      f1_count: f1_count,
      eastboston_old_stop_count: eastboston_old_stop_count,
      eastboston_new_stop_count: eastboston_new_stop_count,
      lynn_old_stop_count: lynn_old_stop_count,
      lynn_new_stop_count: lynn_new_stop_count
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
