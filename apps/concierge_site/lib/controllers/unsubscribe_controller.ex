defmodule ConciergeSite.UnsubscribeController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.Trip

  def update(conn, %{"id" => user_id}) do
    Trip.get_trips_by_user(user_id)
    |> Enum.each(&Trip.pause(&1, user_id))

    json(conn, %{status: "ok"})
  end
end
