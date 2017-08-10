defmodule AlertProcessor.Model.UserTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.User

  @valid_attrs %{email: "email@test.com", role: "user", password: "password1"}
  @valid_account_attrs %{
    "email" => "test@email.com",
    "password" => "Password1",
    "password_confirmation" => "Password1",
    "sms_toggle" => "false"
  }
  @valid_admin_account_attrs %{
    "email" => "test@email.com",
    "password" => "Password1",
    "password_confirmation" => "Password1",
    "role" => "customer_support"
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

    test "does not authenticate if user's account is disabled" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @disabled_password})
      assert {:error, :disabled} = User.authenticate(%{"email" => "test@email.com", "password" => @password})
    end
  end

  describe "create_account" do
    test "creates new account" do
      assert {:ok, user} = User.create_account(@valid_account_attrs)
      assert user.id != nil
    end

    test "does not create new account" do
      assert {:error, changeset} = User.create_account(Map.put(@valid_account_attrs, "password_confirmation", "Garbage"))
      refute changeset.valid?
    end
  end

  describe "create_admin_account" do
    test "creates new admin account" do
      assert {:ok, user} = User.create_admin_account(@valid_admin_account_attrs)
      assert user.id != nil
    end

    test "does not create new account" do
      assert {:error, changeset} =
        User.create_admin_account(Map.put(@valid_admin_account_attrs,
                                "role", nil))
      refute changeset.valid?
    end

    test "cannot have an invalid role name" do
      assert {:error, changeset} =
        User.create_admin_account(Map.put(@valid_admin_account_attrs,
                                          "role", "super_user"))
      refute changeset.valid?
    end
  end

  describe "authenticate_admin/1" do
    test "authenticates if email and password are valid and user has the application_administration role" do
      Repo.insert!(%User{email: "test@email.com", role: "application_administration", encrypted_password: @encrypted_password})
      assert {:ok, _, "application_administration"} = User.authenticate_admin(%{"email" => "test@email.com", "password" => @password})
    end

    test "authenticates if email and password are valid and user has the customer_support role" do
      Repo.insert!(%User{email: "test@email.com", role: "customer_support", encrypted_password: @encrypted_password})
      assert {:ok, _, "customer_support"} = User.authenticate_admin(%{"email" => "test@email.com", "password" => @password})
    end

    test "does not authenticate if email and password are valid but user has user role" do
      Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
      assert :unauthorized = User.authenticate_admin(%{"email" => "test@email.com", "password" => @password})
    end

    test "does not authenticate if user has been deactivated by admin" do
      Repo.insert!(%User{
        email: "test@email.com",
        role: "deactivated_admin",
        encrypted_password: @encrypted_password
      })
      assert :deactivated = User.authenticate_admin(%{"email" => "test@email.com", "password" => @password})
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

    test "sets do_not_disturb period from 10PM to 7AM Eastern" do
      changeset = User.create_account_changeset(%User{}, @valid_account_attrs)

      assert changeset.changes.do_not_disturb_start == ~T[02:00:00]
      assert changeset.changes.do_not_disturb_end == ~T[11:00:00]
    end
  end

  describe "update_account" do
    test "updates account" do
      user = insert(:user)
      assert {:ok, user} = User.update_account(user, %{"amber_alert_opt_in" => "true"})
      assert user.amber_alert_opt_in
    end

    test "does not update account" do
      user = insert(:user)
      assert {:error, changeset} = User.update_account(user, %{"amber_alert_opt_in" => "no way!"})
      refute changeset.valid?
    end
  end

  describe "disable_account" do
    test "removes password and puts into indefinite vacation mode" do
      user = insert(:user)
      assert {:ok, user} = User.disable_account(user)
      assert DateTime.compare(user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
      assert user.encrypted_password == ""
    end
  end

  describe "update_password" do
    test "updates password" do
      user = insert(:user)
      current_password = user.encrypted_password
      assert {:ok, user} = User.update_password(user, %{"password" => "Password1", "password_confirmation" => "Password1"})
      assert current_password != user.encrypted_password
    end

    test "does not update password" do
      user = insert(:user)
      assert {:error, changeset} = User.update_password(user, %{"password" => "Password1", "password_confirmation" => "Garbage"})
      refute changeset.valid?
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

  describe "update_vacation" do
    test "updates vacation" do
      user = insert(:user)
      assert user.vacation_start == nil
      assert user.vacation_end == nil
      {:ok, user} = User.update_vacation(user, %{"vacation_start" => "2017-09-01T00:00:00+00:00", "vacation_end" => "2035-09-01T00:00:00+00:00"})
      assert DateTime.compare(user.vacation_start, DateTime.from_naive!(~N[2017-09-01 00:00:00], "Etc/UTC")) == :eq
      assert DateTime.compare(user.vacation_end, DateTime.from_naive!(~N[2035-09-01 00:00:00], "Etc/UTC")) == :eq
    end

    test "does not update vacation" do
      user = insert(:user)
      {:error, changeset} = User.update_vacation(user, %{"vacation_start" => "2017-09-01T00:00:00+00:00", "vacation_end" => "2015-09-01T00:00:00+00:00"})
      refute changeset.valid?
    end
  end

  describe "update_vacation_changeset" do
    test "will create a valid changeset with end time in the future" do
      changeset = User.update_vacation_changeset(%User{}, %{"vacation_start" => "2017-09-01T00:00:00+00:00", "vacation_end" => "2035-09-01T00:00:00+00:00"})
      assert changeset.valid?
    end

    test "will create an invalid changeset with vacation_end in past" do
      changeset = User.update_vacation_changeset(%User{}, %{"vacation_start" => "2014-09-01T00:00:00+00:00", "vacation_end" => "2015-09-01T00:00:00+00:00"})
      refute changeset.valid?
      assert changeset.errors[:vacation_end] == {"Vacation period must end sometime in the future.", []}
    end

    test "will create an invalid changeset with vacation_end before vacation_start" do
      changeset = User.update_vacation_changeset(%User{}, %{"vacation_start" => "2037-09-01T00:00:00+00:00", "vacation_end" => "2035-09-01T00:00:00+00:00"})
      refute changeset.valid?
      assert changeset.errors[:vacation_end] == {"Vacation period must have an end time later than the start time.", []}
    end
  end

  describe "remove_vacation" do
    test "removes vacation" do
      user = insert(:user, vacation_start: ~N[2017-07-01 00:00:00], vacation_end: ~N[2099-07-01 00:00:00])
      {:ok, user} = User.remove_vacation(user)
      assert user.vacation_start == nil
      assert user.vacation_end == nil
    end
  end

  describe "remove_vacation_changeset" do
    test "will create a valid changeset when vacation period is set" do
      changeset = User.remove_vacation_changeset(%User{vacation_start: ~N[2017-07-01 00:00:00], vacation_end: ~N[2018-07-01 00:00:00]})
      assert changeset.valid?
    end

    test "will create a valid changeset when vacation period is not set" do
      changeset = User.remove_vacation_changeset(%User{vacation_start: nil, vacation_end: nil})
      assert changeset.valid?
    end
  end

  describe "put_users_on_indefinite_vacation" do
    test "it sets list of users on vacation with an end time in the year 9999" do
      user0 = insert(:user)
      user1 = insert(:user)
      {:ok,
        %{
          {:user, 0} => %{model: user_0},
          {:user, 1} => %{model: user_1},
        }
      } = User.put_users_on_indefinite_vacation([user0.id, user1.id])
      assert DateTime.compare(user_0.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
      assert DateTime.compare(user_1.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
    end

    test "doesnt do anything if no users are passed" do
      assert {:ok, %{}} = User.put_users_on_indefinite_vacation([])
    end
  end

  describe "put_user_on_indefinite_vacation" do
    test "puts user on vacation with end time in year 9999" do
      user = insert(:user)
      {:ok, user} = User.put_user_on_indefinite_vacation(user)
      assert DateTime.compare(user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
    end
  end

  describe "deactivate_admin/1" do
    test "changes a user's role to deactivated_admin" do
      user = insert(:user, role: "application_administration")

      assert {:ok, %User{role: "deactivated_admin"}} = User.deactivate_admin(user)
    end
  end

  describe "activate_admin/2" do
    test "changes a user's role to the role passed in params" do
      user = insert(:user, role: "deactivated_admin")
      params = %{"role" => "customer_support"}

      assert {:ok, %User{role: "customer_support"}} = User.activate_admin(user, params)
    end

    test "returns an invalid changeset if passed empty role param" do
      user = insert(:user)
      invalid_params = %{"role" => ""}
      {_, changeset} = User.activate_admin(user, invalid_params)

      refute changeset.valid?
    end

    test "returns an invalid changeset if passed a role other than active admin roles" do
      user = insert(:user)
      invalid_params = %{"role" => "deactivated_admin"}
      {_, changeset} = User.activate_admin(user, invalid_params)

      refute changeset.valid?
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

  describe "all_admin_users/0" do
    test "returns all users with admin roles" do
      application_admin = insert(:user, role: "application_administration")
      customer_support = insert(:user, role: "customer_support")
      user = insert(:user, role: "user")

      all_admin_users = User.all_admin_users()

      assert application_admin in all_admin_users
      assert customer_support in all_admin_users
      refute user in all_admin_users
    end
  end

  describe "admin_one!/1" do
    test "returns an admin user with matching id" do
      user = insert(:user, role: "application_administration")
      assert user == User.admin_one!(user.id)
    end

    test "raises an exception if matching user is not an admin" do
      user = insert(:user, role: "user")

      assert_raise Ecto.NoResultsError, fn ->
        User.admin_one!(user.id)
      end
    end

    test "raises an exception if no user matches id" do
      fake_id = "01cea8b6-7031-4dce-9781-9578777e6135"

      assert_raise Ecto.NoResultsError, fn ->
        User.admin_one!(fake_id)
      end
    end
  end

  describe "ordered_by_email/0" do
    test "returns users in order by email address" do
      user1 = insert(:user, email: "test_user@gmail.com")
      user2 = insert(:user, email: "another_test_user@gmail.com")

      assert [^user2, ^user1] = User.ordered_by_email()
    end
  end

  describe "search_by_contact_info/1" do
    test "filters by email" do
      user1 = insert(:user, email: "one@email.com")
      user2 = insert(:user, email: "two@email.com")

      assert [^user1] = User.search_by_contact_info("one")
      assert [^user2] = User.search_by_contact_info("two")
      assert [^user1, ^user2] = User.search_by_contact_info("email")
    end

    test "filters by phone_number" do
      user1 = insert(:user, email: "a@email.com", phone_number: "5551231234")
      user2 = insert(:user, email: "b@email.com", phone_number: "5553559999")

      assert [^user1] = User.search_by_contact_info("1234")
      assert [^user2] = User.search_by_contact_info("9999")
      assert [^user1, ^user2] = User.search_by_contact_info("555")
    end
  end

  describe "is_admin?/1" do
    test "returns true if the user is an administrator" do
      admin = build(:user, role: "application_administration")

      assert User.is_admin?(admin) == true
    end

    test "returns false if the user is not an administrator" do
      admin = build(:user, role: "user")

      assert User.is_admin?(admin) == false
    end
  end

end
