defmodule ConciergeSite.ViewHelpers do
  @moduledoc "Helpers available in all views."

  @spec external_url(atom) :: String.t()
  def external_url(key) do
    :concierge_site |> Application.fetch_env!(:external_urls) |> Keyword.fetch!(key)
  end

  def google_tag_manager_id, do: env(:google_tag_manager_id)

  defp env(key), do: Application.get_env(:concierge_site, __MODULE__)[key]
end
