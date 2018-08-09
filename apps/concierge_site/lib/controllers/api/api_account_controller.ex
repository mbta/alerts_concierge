defmodule ConciergeSite.ApiAccountController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo

  def delete(conn, %{"user_id" => user_id}) do
    User
    |> Repo.get!(user_id)
    |> User.delete()

    json(conn, %{result: "success"})
  end
end
