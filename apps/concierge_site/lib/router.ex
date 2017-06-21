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
    resources "/account", AccountController, only: [:new, :create]
    resources "/login", SessionController, only: [:new, :create, :delete], singleton: true
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth]
    get "/my-subscriptions", SubscriptionController, :index
    get "/my-account", AccountController, :index
    resources "/subscriptions", SubscriptionController, only: [:new, :edit]
  end

  scope "/subscriptions", ConciergeSite do
    pipe_through [:browser, :browser_auth]
    resources "/subway", SubwaySubscriptionController, only: [:new]
    get "/subway/new/info", SubwaySubscriptionController, :info
    post "/subway/new/preferences", SubwaySubscriptionController, :preferences
    resources "/bus", BusSubscriptionController, only: [:new]
    get "/bus/new/info", BusSubscriptionController, :info
    resources "/commuter_rail", CommuterRailSubscriptionController, only: [:new]
    get "/commuter_rail/new/info", CommuterRailSubscriptionController, :info
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
