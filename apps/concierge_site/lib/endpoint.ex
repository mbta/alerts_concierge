defmodule ConciergeSite.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :concierge_site

  if Application.compile_env(:alert_processor, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  socket("/socket", ConciergeSite.UserSocket, websocket: true)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :concierge_site,
    gzip: true,
    only_matching: ~w(css fonts images js favicon robots)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(RemoteIp, headers: ["x-forwarded-for"])
  plug(Plug.RequestId)
  plug(Logster.Plugs.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Sentry.PlugContext)

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_mbta_concierge_key",
    signing_salt: "SHoiHw+G"
  )

  plug(ConciergeSite.Router)
end
