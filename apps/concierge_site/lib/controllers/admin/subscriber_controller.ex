defmodule ConciergeSite.Admin.SubscriberController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  alias AlertProcessor.Model.User

  def index(conn, params, _user, _claims) do
    users =
      case params["search"] do
        nil -> User.ordered_by_email()
        "" -> User.ordered_by_email()
        search_term -> User.search_by_contact_info(search_term)
      end
    render conn, "index.html", users: users, search_term: params["search"]
  end
end
