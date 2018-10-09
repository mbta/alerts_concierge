defmodule ConciergeSite.HelpTextHelper do
  @moduledoc """
  Render help text in templates
  """
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [raw: 1]

  @spec link(String.t()) :: Phoenix.HTML.safe()
  def link(id) do
    content_tag :a,
      href: "#show",
      data: [type: "help-link", message_id: id],
      class: "helptext__link" do
      ConciergeSite.IconViewHelper.icon(:help)
    end
  end

  @spec message(String.t(), String.t()) :: Phoenix.HTML.safe()
  def message(id, message) do
    content_tag :div, data: [type: "help-message", message_id: id], class: "helptext__message" do
      [close_message(id), raw(message)]
    end
  end

  @spec close_message(String.t()) :: Phoenix.HTML.safe()
  defp close_message(id) do
    content_tag :a,
      href: "#close",
      data: [type: "close-help-text", message_id: id],
      class: "helptext__message--close" do
      content_tag :i, class: "fa fa-times-circle helptext__message--close-icon" do
        ""
      end
    end
  end
end
