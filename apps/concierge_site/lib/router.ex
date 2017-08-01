defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug ConciergeSite.Plugs.TokenLogin
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated,
      handler: ConciergeSite.SessionController
  end

  pipeline :disable_account_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Auth.ErrorHandler, default: [:disable_account]
  end

  pipeline :full_auth do
    plug Guardian.Plug.EnsurePermissions, handler: ConciergeSite.Auth.ErrorHandler, default: [:full_permissions]
  end

  pipeline :admin_auth do
    plug Guardian.Plug.EnsurePermissions,
      [handler: ConciergeSite.Admin.SessionController, admin: ["customer_support"]]
  end

  scope "/", ConciergeSite do
    pipe_through :browser

    get "/", PageController, :index
    resources "/account", AccountController, only: [:new, :create]
    resources "/login", SessionController, only: [:new, :create, :delete], singleton: true
    get "/reset-password/sent", PasswordResetController, :sent
    resources "/reset-password", PasswordResetController, only: [:new, :create, :edit, :update]
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
    get "/my-subscriptions", SubscriptionController, :index
    resources "/my-account", MyAccountController, only: [:edit, :update], singleton: true do
      resources "/password", PasswordController, only: [:edit, :update], singleton: true
      resources "/vacation", VacationController, only: [:edit, :update, :delete], singleton: true
    end
    get "/subscriptions/:id/confirm_delete", SubscriptionController, :confirm_delete
    resources "/subscriptions", SubscriptionController, only: [:new, :edit, :delete]
  end

  scope "/subscriptions", ConciergeSite do
    pipe_through [:browser, :browser_auth, :full_auth]
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
    post "/amenities/add_station", AmenitySubscriptionController, :add_station
    patch "/amenities/add_station", AmenitySubscriptionController, :add_station
    post "/amenities/remove_station/:station", AmenitySubscriptionController, :remove_station
    patch "/amenities/remove_station/:station", AmenitySubscriptionController, :remove_station
    resources "/amenities", AmenitySubscriptionController,
      only: [:new, :create, :edit, :update]
  end

  scope "/admin", ConciergeSite, as: :admin do
    pipe_through :browser

    resources "/login", Admin.SessionController, only: [:new, :create], singleton: true
  end

  scope "/admin", ConciergeSite, as: :admin do
    pipe_through [:browser, :browser_auth, :admin_auth]

    resources "/subscribers", Admin.SubscriberController, only: [:index]
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
