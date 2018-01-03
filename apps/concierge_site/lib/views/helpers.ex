defmodule ConciergeSite.ViewHelpers do
  def google_tag_manager_id do
    case env(:google_tag_manager_id) do
      "" -> nil
      id -> id
    end
  end

  defp env(key), do: Application.get_env(:concierge_site, __MODULE__)[key]
end
