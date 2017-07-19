defmodule ConciergeSite.PasswordHelper do
  @moduledoc """
  Functions for templates with password inputs
  """

  @doc """
  Returns a regular expression for validating passwords in the pattern option
  for HTML.Form.password_input/3
  """
  @spec password_regex_string :: String.t
  def password_regex_string do
    "(?=^.{6,}$)((?=.*\\d)|(?=.*\\W+))(?![.\\n])(?=.*[a-zA-Z]).*$"
  end
end
