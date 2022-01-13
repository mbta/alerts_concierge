defmodule ConciergeSite.Guardian.AuthPipeline do
  @moduledoc "Guardian pipeline for ConciergeSite."

  use Guardian.Plug.Pipeline,
    otp_app: :concierge_site,
    module: ConciergeSite.Guardian,
    error_handler: ConciergeSite.Guardian.AuthErrorHandler

  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.EnsureAuthenticated)
  plug(Guardian.Plug.LoadResource, ensure: true)
end
