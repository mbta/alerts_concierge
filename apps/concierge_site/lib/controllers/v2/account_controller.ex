defmodule ConciergeSite.V2.AccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.ConfirmationMessage
  alias ConciergeSite.SignInHelper

  def new(conn, _params, _user, _claims) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render conn, "new.html", account_changeset: account_changeset
  end

  def create(conn, %{"user" => params}, _user, _claims) do
    case User.create_account(Map.merge(params, %{"password_confirmation" => params["password"]})) do
      {:ok, user} ->
        ConfirmationMessage.send_confirmation(user)
        SignInHelper.sign_in(conn, user, redirect: :v2_default)
      {:error, changeset} ->
        render conn, "new.html", account_changeset: changeset, errors: errors(changeset)
    end
  end

  def options_new(conn, _params, user, _claims) do
    changeset = User.update_account_changeset(user)

    render conn, "options_new.html", changeset: changeset, user: user, sms_toggle: false
  end

  def options_create(conn, %{"user" => user_params}, user, {:ok, claims}) do
    params = Map.merge(user_params, options_params(user_params))

    case User.update_account(user, params, Map.get(claims, "imp", user.id)) do
      {:ok, user} ->
        :ok = User.clear_holding_queue_for_user_id(user.id)
        conn
        |> redirect(to: v2_page_path(conn, :trip_type))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Preferences could not be saved. Please see errors below.")
        |> render("options_new.html", user: user, changeset: changeset, sms_toggle: sms_toggle?(user_params))
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end

  defp options_params(%{"sms_toggle" => "true", "phone_number" => phone_number}) do
    %{"phone_number" => String.replace(phone_number, ~r/\D/, "")}
  end
  defp options_params(%{"sms_toggle" => "false"}), do: %{"phone_number" => nil}
  defp options_params(_), do: %{}

  defp sms_toggle?(%{"sms_toggle" => "true"}), do: true
  defp sms_toggle?(_), do: false
end
