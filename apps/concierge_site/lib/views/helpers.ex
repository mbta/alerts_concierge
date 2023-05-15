defmodule ConciergeSite.ViewHelpers do
  @moduledoc "Helpers available in all views."

  alias AlertProcessor.Helpers.ConfigHelper
  alias Phoenix.HTML.Tag

  @spec external_url(atom) :: String.t()
  def external_url(key) do
    Application.fetch_env!(:concierge_site, :external_urls) |> Keyword.fetch!(key)
  end

  def google_tag_manager_id do
    Application.get_env(:concierge_site, __MODULE__, []) |> Keyword.get(:google_tag_manager_id)
  end

  def informizely_account_deleted_survey,
    do:
      Tag.content_tag(:div, "", id: "informizely-embed-#{informizely_account_deleted_survey_id()}")

  def informizely_site_id, do: ConfigHelper.get_string(:informizely_site_id, :concierge_site)

  @spec informizely_account_deleted_survey_id :: String.t()
  defp informizely_account_deleted_survey_id,
    do: ConfigHelper.get_string(:informizely_account_deleted_survey_id, :concierge_site)
end
