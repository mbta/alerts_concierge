defmodule ConciergeSite.V2.AccessibilityTripController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def create(conn, _params, _user, {:ok, _claims}) do
    conn
    |> put_flash(:info, "Success! Accessibility trip created.")
    |> redirect(to: v2_trip_path(conn, :index))
  end
end
