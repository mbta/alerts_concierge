defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.{PasswordReset, User}
  alias AlertProcessor.Repo
  alias Calendar.DateTime
  alias ConciergeSite.{Email, PasswordResetMailer}

  def new(conn, _params) do
    changeset = PasswordReset.create_changeset(%PasswordReset{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    query = from u in User, select: u.id, where: ilike(u.email, ^email)
    user_id = Repo.one(query)

    changeset = PasswordReset.create_changeset(
      %PasswordReset{},
      %{user_id: user_id, redeemed_at: nil, expired_at: DateTime.add!(DateTime.now_utc, 3600)}
    )
    case Repo.insert(changeset) do
      {:ok, password_reset} ->
        Email.password_reset_html_email(email, password_reset.id)
        |> PasswordResetMailer.deliver_later

        redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
      {:error, changeset} ->
        handle_unknown_email(conn, changeset, email)
    end
  end

  def sent(conn, %{"email" => email}) do
    render conn, "sent.html", email: email
  end

  def show(conn, _params) do
    render conn, "show.html"
  end

  defp handle_unknown_email(conn, changeset, _email) do
    render conn, "new.html", changeset: changeset
  end
end
