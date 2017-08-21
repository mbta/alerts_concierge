defmodule ConciergeSite.HTMLTestHelper do
  @moduledoc """
  Functions to help test functions that return HTML
  """

  @doc """
  Returns a string of html tags and content from a keyword list of safe html
  """
  @spec html_to_binary([[safe: list]]) :: String.t
  def html_to_binary(html_list) do
    html_list |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end
