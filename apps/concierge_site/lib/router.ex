defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ConciergeSite.Plugs.Authorized
    plug ConciergeSite.Plugs.FeedbackPlug
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

  pipeline :v2_layout do
    plug :put_layout, {ConciergeSite.V2.LayoutView, :app}
  end

  scope "/", ConciergeSite do
    # no pipe
    get "/_health", HealthController, :index
  end

  scope "/", ConciergeSite do
    pipe_through :browser

    get "/", PageController, :index
    resources "/login", SessionController, only: [:delete], singleton: true
    post "/rejected_email", RejectedEmailController, :handle_rejected_email
  end

  scope "/v2", ConciergeSite, as: :v2 do
    pipe_through [:browser, :v2_layout]

    get "/", V2.PageController, :index
    get "/trip_type", V2.PageController, :trip_type
    resources "/login", V2.SessionController, only: [:new, :create, :delete], singleton: true
    resources "/account", V2.AccountController, only: [:new, :create]
  end

  scope "/v2", ConciergeSite, as: :v2 do
    pipe_through [:browser, :browser_auth, :subscription_auth, :v2_layout]

    get "/account/options", V2.AccountController, :options_new
    post "/account/options", V2.AccountController, :options_create
    resources "/trips", V2.TripController, only: [:index, :edit, :update, :delete]
    resources "/trip", V2.TripController, only: [:new, :create], singleton: true do
      post "/leg", V2.TripController, :leg
      post "/times", V2.TripController, :times
      get "/type", V2.TripController, :type
    end
    resources "/accessibility_trips", V2.AccessibilityTripController, only: [:new, :create, :edit, :update]
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
