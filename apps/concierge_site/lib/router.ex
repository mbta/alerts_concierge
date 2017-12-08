defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ConciergeSite.Plugs.Authorized
  end

  pipeline :browser_auth do
    plug ConciergeSite.Plugs.TokenLogin
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated,
      handler: ConciergeSite.SessionController
    plug ConciergeSite.Plugs.TokenRefresh
    plug ConciergeSite.Plugs.Authorized
  end

  pipeline :disable_account_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Auth.ErrorHandler, default: [:disable_account]
  end

  pipeline :subscription_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Auth.ErrorHandler, default: [:manage_subscriptions]
  end

  pipeline :full_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Auth.ErrorHandler, default: [:full_permissions]
  end

  pipeline :admin_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Admin.SessionController, admin: [:customer_support]
  end

  scope "/", ConciergeSite do
    pipe_through :browser

    get "/", PageController, :index
    get "/intro", AccountController, :intro
    resources "/account", AccountController, only: [:new, :create]
    resources "/login", SessionController, only: [:new, :create, :delete], singleton: true
    get "/reset-password/sent", PasswordResetController, :sent
    resources "/reset-password", PasswordResetController, only: [:new, :create, :edit, :update]
    post "/unsubscribe", UnsubscribeController, :unsubscribe_confirmed
    get "/unsubscribe/:token", UnsubscribeController, :unsubscribe
    post "/rejected_email", RejectedEmailController, :handle_rejected_email
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth, :disable_account_auth]
    get "/my-account/confirm_disable", MyAccountController, :confirm_disable
    delete "/my-account", MyAccountController, :delete
    get "/account_disabled", PageController, :account_disabled
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth, :full_auth]

    resources "/my-account", MyAccountController, only: [:edit, :update], singleton: true do
      resources "/password", PasswordController, only: [:edit, :update], singleton: true
      resources "/vacation", VacationController, only: [:edit, :update, :delete], singleton: true
    end
    resources "/impersonate_sessions", ImpersonateSessionController, only: [:delete], singleton: true
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth, :subscription_auth]

    get "/my-subscriptions", SubscriptionController, :index
    get "/subscriptions/:id/confirm_delete", SubscriptionController, :confirm_delete
    resources "/subscriptions", SubscriptionController, only: [:new, :edit, :delete]
  end

  scope "/subscriptions", ConciergeSite do
    pipe_through [:browser, :browser_auth, :subscription_auth]
    resources "/subway", SubwaySubscriptionController,
      only: [:new, :edit, :update, :create]
    get "/subway/new/info", SubwaySubscriptionController, :info
    post "/subway/new/preferences", SubwaySubscriptionController, :preferences
    resources "/bus", BusSubscriptionController,
      only: [:new, :edit, :update, :create]
    get "/bus/new/info", BusSubscriptionController, :info
    post "/bus/new/preferences", BusSubscriptionController, :preferences
    resources "/commuter_rail", CommuterRailSubscriptionController,
      only: [:new, :create, :edit, :update]
    get "/commuter_rail/new/info", CommuterRailSubscriptionController, :info
    post "/commuter_rail/new/train", CommuterRailSubscriptionController, :train
    post "/commuter_rail/new/preferences", CommuterRailSubscriptionController, :preferences
    resources "/ferry", FerrySubscriptionController, only: [:new, :create, :edit, :update]
    get "/ferry/new/info", FerrySubscriptionController, :info
    post "/ferry/new/ferry", FerrySubscriptionController, :ferry
    post "/ferry/new/preferences", FerrySubscriptionController, :preferences
    resources "/amenities", AmenitySubscriptionController,
      only: [:new, :create, :edit, :update]
    resources "/accessibility", AccessibilitySubscriptionController,
      only: [:new, :create, :edit, :update]
    resources "/parking", ParkingSubscriptionController,
      only: [:new, :create, :edit, :update]
  end

  scope "/admin", ConciergeSite, as: :admin do
    pipe_through :browser

    resources "/login", Admin.SessionController, only: [:new, :create, :delete], singleton: true
  end

  scope "/admin", ConciergeSite, as: :admin do
    pipe_through [:browser, :browser_auth, :admin_auth]

    resources "/subscribers", Admin.SubscriberController, only: [:index, :show] do
      get "/new_message", Admin.SubscriberController, :new_message
      post "/new_message", Admin.SubscriberController, :send_message
    end
    resources "/subscription_search/:user_id", Admin.SubscriptionSearchController, only: [:new, :create]
    patch "/admin_users/:id/deactivate", Admin.AdminUserController, :deactivate
    patch "/admin_users/:id/activate", Admin.AdminUserController, :activate
    get "/admin_users/:id/confirm_role_change", Admin.AdminUserController, :confirm_role_change

    resources "/admin_users", Admin.AdminUserController, only: [:index, :show, :new, :create, :update]
    resources "/my-account", Admin.MyAccountController, only: [:edit, :update], singleton: true
    resources "/impersonate_sessions", Admin.ImpersonateSessionController, only: [:create]

    get "/admin_users/:id/confirm_deactivate", Admin.AdminUserController, :confirm_deactivate
    get "/admin_users/:id/confirm_activate", Admin.AdminUserController, :confirm_activate
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
