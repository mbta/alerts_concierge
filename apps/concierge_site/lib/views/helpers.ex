defmodule ConciergeSite.ViewHelpers do
  @moduledoc "Helpers available in all views."

  @spec external_url(atom) :: String.t()
  def external_url(key) do
    Application.fetch_env!(:concierge_site, :external_urls) |> Keyword.fetch!(key)
  end

  def google_tag_manager_id do
    Application.get_env(:concierge_site, __MODULE__, []) |> Keyword.get(:google_tag_manager_id)
  end
end
