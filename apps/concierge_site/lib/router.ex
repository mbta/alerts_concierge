defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(ConciergeSite.Plugs.Authorized)
    plug(ConciergeSite.Plugs.FeedbackPlug)
  end

  pipeline :browser_auth do
    plug(ConciergeSite.Plugs.TokenLogin)
    plug(Guardian.Plug.VerifySession)
    plug(Guardian.Plug.LoadResource)
    plug(Guardian.Plug.EnsureAuthenticated, handler: ConciergeSite.SessionController)
    plug(ConciergeSite.Plugs.TokenRefresh)
    plug(ConciergeSite.Plugs.Authorized)
  end

  pipeline :disable_account_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Auth.ErrorHandler,
      default: [:disable_account]
    )
  end

  pipeline :subscription_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Auth.ErrorHandler,
      default: [:manage_subscriptions]
    )
  end

  pipeline :full_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Auth.ErrorHandler,
      default: [:full_permissions]
    )
  end

  pipeline :admin_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Admin.SessionController,
      admin: [:customer_support]
    )
  end

  pipeline :layout do
    plug(:put_layout, {ConciergeSite.LayoutView, :app})
  end

  pipeline :redirect_prod_http do
    if Application.get_env(:concierge_site, :redirect_http?) do
      plug(Plug.SSL, rewrite_on: [:x_forwarded_proto])
    end
  end

  scope "/", ConciergeSite do
    # no pipe
    get("/_health", HealthController, :index)
    get("/_five_hundred", ErrorController, :five_hundred)
    get("/_raise", ErrorController, :raise)
  end

  scope "/", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser])

    post("/rejected_email", RejectedEmailController, :handle_rejected_email)
  end

  scope "/", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser, :layout])

    get("/", PageController, :landing)
    get("/deleted", PageController, :account_deleted)
    resources("/login", SessionController, only: [:new, :create, :delete], singleton: true)
    resources("/account", AccountController, only: [:new, :create])
    resources("/password_resets", PasswordResetController, only: [:new, :create, :edit, :update])
  end

  scope "/", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser, :browser_auth, :subscription_auth, :layout])

    get("/account/options", AccountController, :options_new)
    post("/account/options", AccountController, :options_create)
    get("/account/edit", AccountController, :edit)
    post("/account/edit", AccountController, :update)
    delete("/account/delete", AccountController, :delete)
    get("/password/edit", AccountController, :edit_password)
    post("/password/edit", AccountController, :update_password)

    resources("/trips", TripController, only: [:index, :edit, :update, :delete]) do
      patch("/pause", TripController, :pause, as: :pause)
      patch("/resume", TripController, :resume, as: :resume)
    end

    resources "/trip", TripController, only: [:new, :create], singleton: true do
      post("/leg", TripController, :leg)
      post("/times", TripController, :times)
    end

    resources(
      "/accessibility_trips",
      AccessibilityTripController,
      only: [:new, :create, :edit, :update]
    )
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.EmailPreviewPlug)
  end
end
