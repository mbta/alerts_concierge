defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.{PasswordReset, User}
  alias AlertProcessor.Repo
  alias Calendar.DateTime
  alias ConciergeSite.{Email, Mailer}
  alias Ecto.Multi

  @email_regex ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/

  def new(conn, _params) do
    changeset = PasswordReset.create_changeset(%PasswordReset{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    user_id = find_user_id_by_email(email)

    changeset = PasswordReset.create_changeset(
      %PasswordReset{},
      %{user_id: user_id, redeemed_at: nil, expired_at: DateTime.add!(DateTime.now_utc, 3600)}
    )
    case Repo.insert(changeset) do
      {:ok, password_reset} ->
        Email.password_reset_html_email(email, password_reset.id)
        |> Mailer.deliver_later

        redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
      {:error, changeset} ->
        handle_unknown_email(conn, changeset, email)
    end
  end

  def sent(conn, %{"email" => email}) do
    render conn, "sent.html", email: email
  end

  def edit(conn, %{"id" => id}) do
    password_reset = find_redeemable_password_reset_by_id!(id)
    changeset = User.update_password_changeset(password_reset.user)
    render conn, "edit.html",
      changeset: changeset, password_reset: password_reset
  end
  end

  defp find_user_id_by_email(email) do
    Repo.one(
      from u in User,
      select: u.id,
      where: fragment("lower(?)", u.email) == ^String.downcase(email)
    )
  end

  defp find_redeemable_password_reset_by_id!(id) do
    Repo.one!(from p in PasswordReset,
      where: p.id == ^id and is_nil(p.redeemed_at) and p.expired_at > ^DateTime.now_utc())
    |> Repo.preload([:user])
  end

  defp handle_unknown_email(conn, changeset, email) do
    if String.match?(email, @email_regex) do
      Email.unknown_password_reset_html_email(email)
      |> Mailer.deliver_later

      redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
    else
      conn
      |> put_flash(:error, "Email is not in a valid format.")
      |> render("new.html", changeset: changeset)
    end
  end
end
