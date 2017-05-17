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
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated,
      handler: ConciergeSite.SessionController
  end

  scope "/", ConciergeSite do
    pipe_through :browser

    get "/", PageController, :index
    resources "/login", SessionController, only: [:new, :create, :delete], singleton: true
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth]
    get "/my-subscriptions", SubscriptionController, :index
    get "/my-account", AccountController, :index
    get "/subscriptions/new", SubscriptionController, :new
    get "/subscriptions/new/type", SubscriptionController, :type
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
