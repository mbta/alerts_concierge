defmodule MbtaServer.UserTest do
  use MbtaServer.DataCase

  alias MbtaServer.User

  @valid_attrs %{email: "some email", role: "user", password: "password1"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
