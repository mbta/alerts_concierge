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

  def show(conn, %{"id" => subscriber_id}, user, _claims) do
    subscriber = User.find_by_id(subscriber_id)

    render conn, "show.html", subscriber: subscriber
  end
end
