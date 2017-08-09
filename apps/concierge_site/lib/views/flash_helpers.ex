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
      content_tag :div, class: "error-block-container" do
        content_tag :span, error, class: "error-block text-center"
      end
    end
  end

  @doc """
  Generates flash info tag
  """
  def flash_info(conn) do
    if info = get_flash(conn, :info) do
      content_tag :div, info, class: "alert alert-success"
    end
  end
end
