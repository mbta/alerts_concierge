defmodule ConciergeSite.Router do
  use ConciergeSite.Web, :router
  use Plug.ErrorHandler

  @redirect_http Application.compile_env(:concierge_site, :redirect_http?)

  pipeline :redirect_prod_http do
    if @redirect_http do
      plug(Plug.SSL, rewrite_on: [:x_forwarded_proto])
    end
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)

    plug :put_secure_browser_headers, %{
      "strict-transport-security" => "max-age=31536000",
      "content-security-policy" =>
        "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline' www.googletagmanager.com insitez.blob.core.windows.net;"
    }

    plug(ConciergeSite.Plugs.AssignCurrentUser)
    plug(ConciergeSite.Plugs.RateLimit, enable?: Mix.env() != :test)
  end

  pipeline :browser_auth do
    plug(ConciergeSite.Guardian.AuthPipeline)
    plug(ConciergeSite.Plugs.TokenRefresh)
    plug(ConciergeSite.Plugs.AssignCurrentUser)
  end

  pipeline :admin_auth do
    plug(Guardian.Permissions, ensure: %{admin: [:all]})
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
    pipe_through([:redirect_prod_http])
    post("/unsubscribe/:id", UnsubscribeController, :update)
    post("/rejected_email", RejectedEmailController, :handle_message)
  end

  scope "/", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser, :layout])

    get("/", PageController, :landing)
    get("/login", SessionController, :login_redirect)
    get("/deleted", PageController, :account_deleted)
    get("/feedback", FeedbackController, :feedback)

    get(
      "/email_opened/notification/:alert_id/:notification_id/img.gif",
      EmailOpenedController,
      :notification
    )

    post("/api/feedback", FeedbackController, :new)
    get("/digest/feedback", DigestFeedbackController, :feedback)
    post("/api/digest/feedback", DigestFeedbackController, :new)
    resources("/login", SessionController, only: [:new], singleton: true)
    resources("/account", AccountController, only: [:new, :create])
  end

  scope "/", ConciergeSite do
    pipe_through([:redirect_prod_http, :browser, :browser_auth, :layout])

    resources("/login", SessionController, only: [:delete], singleton: true)

    get("/account/options", AccountController, :options_new)
    post("/account/options", AccountController, :options_create)
    get("/account/edit", AccountController, :edit)
    post("/account/edit", AccountController, :update)
    delete("/account/delete", AccountController, :delete)
    get("/password/edit", AccountController, :edit_password)

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

  scope "/auth", ConciergeSite do
    pipe_through([
      :redirect_prod_http,
      :browser
    ])

    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
    get("/:provider/logout", AuthController, :logout)
  end

  scope "/admin", ConciergeSite.Admin, as: :admin do
    pipe_through([:redirect_prod_http, :browser, :browser_auth, :admin_auth, :layout])

    get("/", HomeController, :index)
    resources("/queries", QueriesController, only: [:index, :show])
  end

  scope "/mailchimp", ConciergeSite do
    post("/update", AccountController, :mailchimp_update)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
