defmodule ConciergeSite.FlashHelpers do
  @moduledoc """
  Conveniences for adding flash messages into templates.
  """

  use Phoenix.HTML
  import Phoenix.Controller, only: [get_flash: 2]

  @doc """
  Generates flash error tag for entire form.
  """
  def flash_error(conn) do
    if error = get_flash(conn, :error) do
      content_tag :div, class: "alert alert-danger", tabindex: "0" do
        content_tag(:span, error, class: "error-block")
      end
    end
  end

  @doc """
  Generates flash warning tag
  """
  def flash_warning(conn) do
    if warning = get_flash(conn, :warning) do
      content_tag(:div, warning, class: "alert alert-warning", tabindex: "0")
    end
  end

  @doc """
  Generates flash info tag
  """
  def flash_info(conn) do
    if info = get_flash(conn, :info) do
      content_tag(:div, info, class: "alert alert-success", tabindex: "0")
    end
  end
end
