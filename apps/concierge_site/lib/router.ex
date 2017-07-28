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
    get "/account_disabled", PageController, :account_disabled
    resources "/account", AccountController, only: [:new, :create]
    resources "/login", SessionController, only: [:new, :create, :delete], singleton: true
    get "/reset-password/sent", PasswordResetController, :sent
    resources "/reset-password", PasswordResetController, only: [:new, :create, :edit, :update]
    get "/unsubscribe/:token", UnsubscribeController, :unsubscribe
  end

  scope "/", ConciergeSite do
    pipe_through [:browser, :browser_auth]
    get "/my-subscriptions", SubscriptionController, :index
    get "/my-account/confirm_disable", MyAccountController, :confirm_disable
    resources "/my-account", MyAccountController, only: [:edit, :update, :delete], singleton: true do
      resources "/password", PasswordController, only: [:edit, :update], singleton: true
      resources "/vacation", VacationController, only: [:edit, :update, :delete], singleton: true
    end
    get "/subscriptions/:id/confirm_delete", SubscriptionController, :confirm_delete
    resources "/subscriptions", SubscriptionController, only: [:new, :edit, :delete]
  end

  scope "/subscriptions", ConciergeSite do
    pipe_through [:browser, :browser_auth]
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

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
