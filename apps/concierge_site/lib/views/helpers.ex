defmodule ConciergeSite.ViewHelpers do
  def google_tag_manager_id, do: env(:google_tag_manager_id)

  defp env(key), do: Application.get_env(:concierge_site, __MODULE__)[key]
end
