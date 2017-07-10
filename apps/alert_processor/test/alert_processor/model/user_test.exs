defmodule AlertProcessor.Model.UserTest do
  use AlertProcessor.DataCase

  alias AlertProcessor.Model.User

  @valid_attrs %{email: "email@test.com", role: "user", password: "password1"}
  @valid_account_attrs %{
    "email" => "test@email.com",
    "password" => "Password1",
    "password_confirmation" => "Password1",
    "sms_toggle" => "false"
  }
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

  describe "create_account_changeset" do
    test "will create a valid changeset with valid params" do
      changeset = User.create_account_changeset(%User{}, @valid_account_attrs)
      assert changeset.valid?
    end

    test "will create a valid changeset with password containing special characters and at least 6 characters" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "P@ssword", "password_confirmation" => "P@ssword"}))
      assert changeset.valid?
    end

    test "will create an invalid changeset with non-matching password_confirmation" do
      changeset = User.create_account_changeset(%User{}, Map.put(@valid_account_attrs, "password_confirmation", "Garbage"))
      refute changeset.valid?
    end

    test "will create an invalid changeset with invalid password that is too short" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "Pass1", "password_confirmation" => "Pass1"}))
      refute changeset.valid?
    end

    test "will create an invalid changeset with invalid password that does not contain a digit or special character" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "Password", "password_confirmation" => "Password"}))
      refute changeset.valid?
    end

    test "if sms_toggle is true, will validate phone number" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"phone_number" => "2342342344", "sms_toggle" => "true"}))
      %{changes: %{phone_number: phone_number}} = changeset
      assert phone_number == "2342342344"
      assert changeset.valid?
    end

    test "if sms_toggle is false, phone_number (if present) will be ignored" do
      changeset = User.create_account_changeset(%User{}, Map.put(@valid_account_attrs, "phone_number", "2342342344"))
      %{changes: changes} = changeset
      refute Map.has_key?(changes, :phone_number)
      assert changeset.valid?
    end
  end

  describe "update_password_changeset" do
    test "will create a valid changeset with password containing special characters and at least 6 characters" do
      changeset = User.update_password_changeset(%User{}, %{"password" => "P@ssword", "password_confirmation" => "P@ssword"})
      assert changeset.valid?
    end

    test "will create an invalid changeset with non-matching password_confirmation" do
      changeset = User.update_password_changeset(%User{}, %{"password" => "P@ssword", "password_confirmation" => "DifferentPassword"})
      refute changeset.valid?
    end

    test "will create an invalid changeset with invalid password that is too short" do
      changeset = User.update_password_changeset(%User{}, %{"password" => "Pass1", "password_confirmation" => "Pass1"})
      refute changeset.valid?
    end

    test "will create an invalid changeset with invalid password that does not contain a digit or special character" do
      changeset = User.update_password_changeset(%User{}, %{"password" => "Password", "password_confirmation" => "Password"})
      refute changeset.valid?
    end
  end
end
