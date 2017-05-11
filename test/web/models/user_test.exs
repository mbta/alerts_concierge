defmodule MbtaServer.UserTest do
  use MbtaServer.DataCase

  alias MbtaServer.User

  @valid_attrs %{email: "email@test.com", role: "user", password: "password1"}
  @invalid_attrs %{}
  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  describe "user changeset" do
    test "changeset with valid attributes" do
      changeset = User.changeset(%User{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = User.changeset(%User{}, @invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "authenticate/1" do
    test "authenticates if email and password valid" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
      assert {:ok, _} = User.authenticate(%{"email" => "test@email.com", "password" => @password})
    end

    test "does not authenticate if invalid password for existing user" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
      assert {:error, _} = User.authenticate(%{"email" => "test@email.com", "password" => "different_password"})
    end

    test "does not authenticate if user doesn't exist" do
      assert {:error, _} = User.authenticate(%{"email" => "nope@invalid.com", "password" => @password})
    end
  end
end
