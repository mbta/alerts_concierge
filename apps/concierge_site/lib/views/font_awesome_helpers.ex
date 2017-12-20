defmodule ConciergeSite.FontAwesomeHelpers do
  @moduledoc """
  Conveniences for using Font Awesome
  """

  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @doc "HTML for a FontAwesome icon, with optional attributes"
  def fa(name, attributes \\ []) when is_list(attributes) do
    content_tag :i, [], [{:"aria-hidden", "true"},
                         {:class, "fa fa-#{name} " <> Keyword.get(attributes, :class, "")} |
                         Keyword.delete(attributes, :class)]
  end
end
