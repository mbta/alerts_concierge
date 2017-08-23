defmodule ConciergeSite.Admin.MyAccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.{Subscription, User}
  alias ConciergeSite.UserParams

  def edit(conn, _params, user, _claims) do
    changeset = User.update_account_changeset(user)
    mode_subscriptions =
      Subscription.full_mode_subscription_types_for_user(user)
    render conn, "edit.html", user: user, changeset: changeset, mode_subscriptions: mode_subscriptions
  end

  def update(conn, %{"user" => user_params} = params, user, _claims) do
    mode_subscription_params = Map.get(params, "mode_subscriptions")
    update_params = UserParams.prepare_for_update_changeset(user_params)

    with {:ok, _user} <- User.update_account(user, update_params, user.id),
         :ok <- Subscription.create_full_mode_subscriptions(user, mode_subscription_params) do
      conn
      |> put_flash(:info, "Account updated.")
      |> redirect(to: admin_my_account_path(conn, :edit))
    else
      {:error, changeset} ->
        mode_subscriptions =
          Subscription.full_mode_subscription_types_for_user(user)

        conn
        |> put_flash(:error, "Account could not be updated. Please see errors below.")
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> assign(:mode_subscriptions, mode_subscriptions)
        |> render("edit.html")
    end
  end
end
