defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.{PasswordReset, User}
  alias AlertProcessor.Repo
  alias Calendar.DateTime
  alias ConciergeSite.Dissemination.{Email, Mailer}
  alias ConciergeSite.SignInHelper
  alias Ecto.Multi

  def new(conn, _params) do
    changeset = PasswordReset.create_changeset(%PasswordReset{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    user = find_user_by_email(email)
    user_id = user && user.id

    changeset = PasswordReset.create_changeset(
      %PasswordReset{},
      %{user_id: user_id, redeemed_at: nil, expired_at: DateTime.add!(DateTime.now_utc, 3600)}
    )
    case Repo.insert(changeset) do
      {:ok, password_reset} ->
        user
        |> Email.password_reset_email(password_reset)
        |> Mailer.deliver_later()

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
    changeset = User.changeset(password_reset.user)

    conn
    |> assign(:changeset, changeset)
    |> assign(:password_reset, password_reset)
    |> render(:edit)
  end

  def update(conn, %{"user" => user_params, "id" => id}) do
    password_reset = find_redeemable_password_reset_by_id!(id)
    password_reset_changeset = PasswordReset.redeem_changeset(password_reset)
    user_changeset = User.update_password_changeset(password_reset.user, user_params)

    multi =
      Multi.new
      |> Multi.update(:user, user_changeset)
      |> Multi.update(:password_reset, password_reset_changeset)

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        conn
        |> put_flash(:info, "Your password has been updated.")
        |> SignInHelper.sign_in(user, redirect: :my_account)
      {:error, :user, changeset, _} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:password_reset, password_reset)
        |> render(:edit)
      {:error, :password_reset, changeset, _} ->
        conn
        |> put_flash(:error, password_reset_errors(changeset))
        |> redirect(to: session_path(conn, :new))
    end
  end

  defp find_user_by_email(email) do
    Repo.one(
      from u in User,
      where: fragment("lower(?)", u.email) == ^String.downcase(email)
    )
  end

  defp find_redeemable_password_reset_by_id!(id) do
    Repo.one!(from p in PasswordReset,
      left_join: u in assoc(p, :user),
      where: p.id == ^id and
        is_nil(p.redeemed_at) and
        p.expired_at > ^DateTime.now_utc() and
        u.role != "deactivated_admin",
      preload: [:user]
    )
  end

  defp handle_unknown_email(conn, changeset, email) do
    if String.match?(email, ~r/@/) do
      email
      |> Email.unknown_password_reset_email()
      |> Mailer.deliver_later()

      redirect(conn, to: password_reset_path(conn, :sent, %{email: email}))
    else
      conn
      |> put_flash(:error, "Email is not in a valid format.")
      |> render("new.html", changeset: changeset)
    end
  end

  defp password_reset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn ({_, {error, _}}) -> error end)
    |> Enum.join(",")
  end
end
