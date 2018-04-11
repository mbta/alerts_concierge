defmodule AlertProcessor.Model.UserTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.User

  @valid_attrs %{email: "email@test.com", role: "user", password: "password1"}
  @valid_account_attrs %{
    "email" => "test@email.com",
    "password" => "Password1",
    "sms_toggle" => "false"
  }
  @invalid_attrs %{}
  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)
  @disabled_password ""

  describe "user changeset" do
    test "changeset with valid attributes" do
      changeset = User.changeset(%User{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = User.changeset(%User{}, @invalid_attrs, ~w(email password)a)
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

    test "does not authenticate if user's account is disabled" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @disabled_password})
      assert {:error, :disabled} = User.authenticate(%{"email" => "test@email.com", "password" => @password})
    end

    test "email is not case sensitive" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
      assert {:ok, _} = User.authenticate(%{"email" => "TEST@EMAIL.COM", "password" => @password})
    end
  end

  describe "create_account" do
    test "creates new account" do
      assert {:ok, user} = User.create_account(@valid_account_attrs)
      assert user.id != nil
    end

    test "removes non digits from phone number input" do
      assert {:ok, user} = User.create_account(Map.merge(@valid_account_attrs, %{"sms_toggle" => "true", "phone_number" => "555-555-1234"}))
      assert user.phone_number == "5555551234"
      assert user.id != nil
    end
  end

  describe "create_account_changeset" do
    test "will create a valid changeset with valid params" do
      changeset = User.create_account_changeset(%User{}, @valid_account_attrs)
      assert changeset.valid?
    end

    test "will create a valid changeset with password containing special characters and at least 6 characters" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "P@ssword"}))
      assert changeset.valid?
    end

    test "will create an invalid changeset with invalid password that is too short" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "Pass1"}))
      refute changeset.valid?
    end

    test "will create an invalid changeset with invalid password that does not contain a digit or special character" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"password" => "Password"}))
      refute changeset.valid?
    end

    test "will create an invalid changeset with an email that does not contain an @" do
      changeset = User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, %{"email" => "emailatexample.com"}))
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

  describe "update_account" do
    test "updates account" do
      user = insert(:user)
      assert {:ok, user} = User.update_account(user, %{"phone_number" => "5550000000"}, user.id)
      assert user.phone_number == "5550000000"
    end

    test "opts in phone number when phone number changed" do
      user = insert(:user)
      assert {:ok, _} = User.update_account(user, %{"phone_number" => "5550000000"}, user.id)
      assert_received :opt_in_phone_number
    end

    test "does not opt in phone number when phone number not changed" do
      user = insert(:user)
      assert {:ok, _} = User.update_account(user, %{}, user.id)
      refute_received :opt_in_phone_number
    end

    test "does not update account" do
      user = insert(:user)
      assert {:error, changeset} = User.update_account(user, %{"phone_number" => "not a phone number"}, user.id)
      refute changeset.valid?
    end
  end

  describe "update_password" do
    test "updates password" do
      user = insert(:user)
      current_password = user.encrypted_password
      assert {:ok, user} = User.update_password(user, %{"password" => "Password1"}, user.id)
      assert current_password != user.encrypted_password
    end
  end

  describe "remove_users_phone_number" do
    test "removes the phone numbers from the users" do
      user0 = insert(:user)
      user1 = insert(:user)

      {:ok,
        %{
          {:user, 0} => %{model: user_0},
          {:user, 1} => %{model: user_1},
        }
      } = User.remove_users_phone_number([user0.id, user1.id], "sms-opt-out")
      assert user_0.phone_number == nil
      assert user_1.phone_number == nil
    end

    test "doesnt do anything if no users are passed" do
      assert {:ok, %{}} = User.remove_users_phone_number([], "sms-opt-out")
    end
  end

  describe "put_user_on_indefinite_vacation" do
    test "puts user on vacation with end time in year 9999" do
      user = insert(:user)
      {:ok, user} = User.put_user_on_indefinite_vacation(user, "email-unsubscribe")
      assert DateTime.compare(user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
    end
  end

  describe "for_email/1" do
    test "returns a user if present" do
      user = insert(:user)
      assert user == User.for_email(user.email)
    end

    test "returns nil if no matching user" do
      assert nil == User.for_email("test@nonexistent.com")
    end
  end

  describe "wrap_id/1" do
    test "wraps id in user struct" do
      assert %User{id: "123-456-7890"} == User.wrap_id("123-456-7890")
    end

    test "returns user struct if provided" do
      assert %User{id: "098-765-4321"} == User.wrap_id(%User{id: "098-765-4321"})
    end
  end
end
