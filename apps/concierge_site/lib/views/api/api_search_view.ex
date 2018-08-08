defmodule ConciergeSite.ApiSearchView do
  use ConciergeSite.Web, :view
  alias __MODULE__

  def render("index.json", %{users: users}) do
    %{users: render_many(users, ApiSearchView, "user.json", as: :user)}
  end

  def render("user.json", %{user: user}) when is_nil(user), do: nil

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      phone_number: user.phone_number
    }
  end
end
