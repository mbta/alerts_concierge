defmodule MbtaServer.Web.Router do
  use MbtaServer.Web, :router

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
  end

  scope "/", MbtaServer.Web do
    pipe_through :browser

    get "/", PageController, :index
    resources "/login", SessionController, only: [:new, :create]
  end

  scope "/", MbtaServer.Web do
    pipe_through [:browser, :browser_auth]
    get "/my-subscriptions", SubscriptionController, :index
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
