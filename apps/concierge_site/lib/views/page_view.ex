defmodule ConciergeSite.PageView do
  use ConciergeSite.Web, :view

  alias ConciergeSite.SessionHelper

  defdelegate keycloak_auth?, to: SessionHelper
end
