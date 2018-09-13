defmodule ConciergeSite.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field, name \\ nil) do
    if error = form.errors[field] do
      content_tag :div, class: "error-block-container" do
        message =
          error
          |> translate_error()
          |> replace_field_name(name)

        content_tag(:span, message, class: "error-block")
      end
    end
  end

  defp replace_field_name(message, nil), do: message
  defp replace_field_name(message, name), do: String.replace(message, "This field", name)

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file.
    # Ecto will pass the :count keyword if the error message is
    # meant to be pluralized.
    # On your own code and templates, depending on whether you
    # need the message to be pluralized or not, this could be
    # written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #     dgettext "errors", "is invalid"
    #
    if count = opts[:count] do
      Gettext.dngettext(ConciergeSite.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ConciergeSite.Gettext, "errors", msg, opts)
    end
  end
end
