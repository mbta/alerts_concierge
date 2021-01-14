defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router

  pipeline :redirect_prod_http do
    if Application.get_env(:concierge_site, :redirect_http?) do
      plug(Plug.SSL, rewrite_on: [:x_forwarded_proto])
    end
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    # We don't actually need flash, but for now it is required in web.ex for views
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(ConciergeSite.Plugs.TokenLogin)
    plug(Guardian.Plug.VerifySession)
    plug(Guardian.Plug.LoadResource)
    plug(Guardian.Plug.EnsureAuthenticated, handler: ConciergeSite.SessionController)
    plug(ConciergeSite.Plugs.TokenRefresh)
    plug(ConciergeSite.Plugs.SaveCurrentUser)
    plug(:admin_auth)
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(ConciergeSite.Plugs.SaveCurrentUser)
  end

  pipeline :browser_auth do
    plug(ConciergeSite.Plugs.TokenLogin)
    plug(Guardian.Plug.VerifySession)
    plug(Guardian.Plug.LoadResource)
    plug(Guardian.Plug.EnsureAuthenticated, handler: ConciergeSite.SessionController)
    plug(ConciergeSite.Plugs.TokenRefresh)
    plug(ConciergeSite.Plugs.SaveCurrentUser)
  end

  pipeline :admin_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Auth.ErrorHandler,
      admin: [:api]
    )
  end

  pipeline :subscription_auth do
    plug(
      Guardian.Plug.EnsurePermissions,
      handler: ConciergeSite.Auth.ErrorHandler,
      default: [:manage_subscriptions]
    )
  end

  pipeline :layout do
    plug(:put_layout, {ConciergeSite.LayoutView, :app})
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
    get("/login", SessionController, :login_redirect)
    get("/deleted", PageController, :account_deleted)
    get("/feedback", FeedbackController, :feedback)
    post("/api/feedback", FeedbackController, :new)
    get("/digest/feedback", DigestFeedbackController, :feedback)
    post("/api/digest/feedback", DigestFeedbackController, :new)
    resources("/login", SessionController, only: [:new, :create, :delete], singleton: true)
    resources("/account", AccountController, only: [:new, :create])
    resources("/password_resets", PasswordResetController, only: [:new, :create, :edit, :update])
  end

  scope "/", ConciergeSite do
    pipe_through([
      :redirect_prod_http,
      :browser,
      :browser_auth,
      :subscription_auth,
      :layout
    ])

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

  scope "/admin", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser, :browser_auth, :admin_auth, :layout])
    get("/", AdminController, :index)
  end

  scope "/api", ConciergeSite do
    pipe_through([:redirect_prod_http, :api])

    get("/search/:query", ApiSearchController, :index)
    delete("/account/:user_id", ApiAccountController, :delete)
  end

  scope "/mailchimp", ConciergeSite do
    # mailchimp needs get and post, even though post is actually used to send data
    get("/update", AccountController, :mailchimp_update)
    post("/update", AccountController, :mailchimp_update)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
