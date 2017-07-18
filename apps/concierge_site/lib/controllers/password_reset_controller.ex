defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.{PasswordReset, User}
  alias AlertProcessor.Repo
  alias Calendar.DateTime
  alias ConciergeSite.{Email, PasswordResetMailer}
  alias Ecto.Multi

  @email_regex ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/

  plug :check_redeemable when action in [:show, :redeem]

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
    changeset = User.update_password_changeset(conn.assigns.user)
    render conn, "show.html", changeset: changeset, password_reset: conn.assigns.password_reset
  end

  def redeem(conn, %{"user" => user_params}) do
    user_changeset = User.update_password_changeset(conn.assigns.user, user_params)
    password_reset_changeset = PasswordReset.redeem_changeset(conn.assigns.password_reset)

    multi =
      Multi.new
      |> Multi.update(:user, user_changeset)
      |> Multi.update(:password_reset, password_reset_changeset)

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Your password has been updated.")
        |> redirect(to: my_account_path(conn, :edit))
      {:error, :user, changeset, _} ->
        render conn, "show.html",
          changeset: changeset,
          password_reset: conn.assigns.password_reset
      _ ->
        conn
        |> put_flash(:error, "The page you were looking for was not found.")
        |> redirect(to: session_path(conn, :new))
    end
  end

  defp handle_unknown_email(conn, changeset, email) do
    if String.match?(email, @email_regex) do
      Email.unknown_password_reset_html_email(email)
      |> PasswordResetMailer.deliver_later

      redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
    else
      conn
      |> put_flash(:error, "Please enter your email address.")
      |> render("new.html", changeset: changeset)
    end
  end

  defp check_redeemable(conn, _params) do
    password_reset =
      PasswordReset
      |> Repo.get!(conn.params["id"])
      |> Repo.preload([:user])
      
    if PasswordReset.redeemable?(password_reset) do
      conn
      |> assign(:password_reset, password_reset)
      |> assign(:user, password_reset.user)
    else
      conn
      |> put_flash(:error, "The page you were looking for was not found.")
      |> redirect(to: session_path(conn, :new))
      |> halt()
    end
  end
end
