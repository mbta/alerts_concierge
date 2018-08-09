defmodule ConciergeSite.ApiSearchController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User

  def index(conn, %{"query" => query}) do
    users =
      (User.find_by_email_search(query) ++ User.find_by_phone_number_search(query)) |> Enum.uniq()

    render(conn, "index.json", users: users)
  end
end
