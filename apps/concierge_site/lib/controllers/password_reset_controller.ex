defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.{PasswordReset, User}
  alias AlertProcessor.Repo
  alias Calendar.DateTime

  def new(conn, _params) do
    changeset = PasswordReset.create_changeset(%PasswordReset{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    query = from u in User, where: ilike(u.email, ^email)

    if user = Repo.one(query) do
      changeset = PasswordReset.create_changeset(
        %PasswordReset{},
        %{user_id: user.id, redeemed_at: nil, expired_at: DateTime.add!(DateTime.now_utc, 3600)}
      )
      Repo.insert(changeset)
    end

    redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
  end

  def sent(conn, %{"email" => email}) do
    render conn, "sent.html", email: email
  end
end
