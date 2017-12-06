defmodule ConciergeSite.FeatureTestHelper do
  @moduledoc """
  Functions to help in feature tests
  """

  use Wallaby.DSL
  alias AlertProcessor.Model.User
  import Wallaby.Query, only: [text_field: 1, button: 1]

  @doc """
  Logs in a user given either:
  1. an email address and password
  2: a user with `email` and `password` fields
  """
  def log_in(session, email, password) do
    session
    |> visit("/")
    |> fill_in(text_field("Email Address"), with: email)
    |> fill_in(text_field("Password"), with: password)
    |> click(button("Sign In"))
  end
  def log_in(session, %User{email: email, password: password}) do
    session
    |> visit("/")
    |> fill_in(text_field("Email Address"), with: email)
    |> fill_in(text_field("Password"), with: password)
    |> click(button("Sign In"))
  end
end
