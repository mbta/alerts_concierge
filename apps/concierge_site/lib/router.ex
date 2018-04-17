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
      handler: ConciergeSite.V2.SessionController
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

  pipeline :redirect_prod_http do
    if Application.get_env(:concierge_site, :redirect_http?) do
      plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
    end
  end

  scope "/", ConciergeSite do
    # no pipe
    get "/_health", HealthController, :index
  end

  scope "/", ConciergeSite do
    pipe_through [:redirect_prod_http, :browser]

    post "/rejected_email", RejectedEmailController, :handle_rejected_email
  end

  scope "/", ConciergeSite, as: :v2 do
    pipe_through [:redirect_prod_http, :browser, :v2_layout]

    get "/", V2.PageController, :index
    get "/trip_type", V2.PageController, :trip_type
    get "/deleted", V2.PageController, :account_deleted
    resources "/login", V2.SessionController, only: [:new, :create, :delete], singleton: true
    resources "/account", V2.AccountController, only: [:new, :create]
    resources "/password_resets",V2.PasswordResetController, only: [:new, :create, :edit, :update]
  end

  scope "/", ConciergeSite, as: :v2 do
    pipe_through [:redirect_prod_http, :browser, :browser_auth, :subscription_auth, :v2_layout]

    get "/account/options", V2.AccountController, :options_new
    post "/account/options", V2.AccountController, :options_create
    get "/account/edit", V2.AccountController, :edit
    post "/account/edit", V2.AccountController, :update
    delete "/account/delete", V2.AccountController, :delete
    get "/password/edit", V2.AccountController, :edit_password
    post "/password/edit", V2.AccountController, :update_password
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
