defmodule ConciergeSite.FeatureTestHelper do
  @moduledoc """
  Functions to help in feature tests
  """

  use Wallaby.DSL
  alias AlertProcessor.Model.User
  import Wallaby.Query, only: [text_field: 1, button: 1, css: 1, css: 2]

  @doc """
  Logs in a user given either:
  1. an email address and password
  2: a user with `email` and `password` fields
  """
  def log_in(session, email, password) do
    session
    |> visit("/login/new")
    |> fill_in(text_field("Email login"), with: email)
    |> fill_in(text_field("Password"), with: password)
    |> click(button("Go to my account"))
  end
  def log_in(session, %User{email: email, password: password}) do
    session
    |> visit("/login/new")
    |> fill_in(text_field("Email login"), with: email)
    |> fill_in(text_field("Password"), with: password)
    |> click(button("Go to my account"))
  end

  @doc """
  Select an item in a select2 dropdown
  The id is the id of the select it's associated with
  The value is the value to select
  """
  def select2(session, id, value) do
    session
    |> click(css("#select2-#{id}-container"))
    |> click(css(".select2-results__option[role=treeitem]", text: value))
  end
end
