defmodule ConciergeSite.FlashHelpers do
  @moduledoc """
  Conveniences for adding flash messages into templates.
  """

  use Phoenix.HTML

  @doc """
  Generates flash error tag for entire form.
  """
  def flash_error(conn) do
    if error = Phoenix.Flash.get(conn.assigns.flash, :error) do
      content_tag :div, class: "alert alert-danger", tabindex: "0" do
        content_tag(:span, error, class: "error-block")
      end
    end
  end

  @doc """
  Generates flash warning tag
  """
  def flash_warning(conn) do
    if warning = Phoenix.Flash.get(conn.assigns.flash, :warning) do
      content_tag(:div, warning, class: "alert alert-warning", tabindex: "0")
    end
  end

  @doc """
  Generates flash info tag
  """
  def flash_info(conn) do
    if info = Phoenix.Flash.get(conn.assigns.flash, :info) do
      content_tag(:div, info, class: "alert alert-success", tabindex: "0")
    end
  end
end
