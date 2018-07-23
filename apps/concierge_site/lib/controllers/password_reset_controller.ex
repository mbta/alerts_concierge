defmodule ConciergeSite.PasswordResetController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.Dissemination.{Email, Mailer}
  alias ConciergeSite.SignInHelper

  action_fallback ConciergeSite.FallbackController

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"password_reset" => %{"email" => email}}) do
    case User.for_email(email) do
      nil ->
        conn
        |> put_flash(:error, "Could not find that email address.")
        |> render("new.html")
      user ->
        reset_token = Phoenix.Token.sign(ConciergeSite.Endpoint, "password_reset", email)
        user |> Email.password_reset_email(reset_token) |> Mailer.deliver_later()
        conn
        |> put_flash(:info, "We've sent you a password reset email. Check your inbox!")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def edit(conn, %{"id" => reset_token}) do
    render(conn, "edit.html", reset_token: reset_token)
  end

  def update(conn, %{"id" => reset_token, "password_reset" => password_reset_params}) do
    two_hours = 7_200
    with {:ok, email} <- verify_token(reset_token, max_age: two_hours),
         user when not is_nil(user) <- User.for_email(email),
         {:ok, :password_confirmation} <- check_password_confirmation(password_reset_params),
         {:ok, _} <- User.update_password(user, password_reset_params, user) do
      conn
      |> put_flash(:info, "Your password has been updated.")
      |> SignInHelper.sign_in(user, redirect: :default)
    else
      {:error, :password_confirmation} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Password confirmation must match.")
        |> render("edit.html", reset_token: reset_token)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, password_reset_errors(changeset))
        |> render("edit.html", reset_token: reset_token, changeset: changeset)
      _ ->
        {:error, :not_found}
    end
  end

  defp verify_token(reset_token, max_age: max_age) do
    Phoenix.Token.verify(ConciergeSite.Endpoint, "password_reset", reset_token, max_age: max_age)
  end

  defp check_password_confirmation(params) do
    if params["password"] == params["password_confirmation"] do
      {:ok, :password_confirmation}
    else
      {:error, :password_confirmation}
    end
  end

  defp password_reset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn ({_, {error, _}}) -> error end)
    |> Enum.join(",")
  end
end
