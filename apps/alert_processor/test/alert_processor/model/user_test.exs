defmodule AlertProcessor.Model.UserTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Model.User

  doctest User

  @valid_attrs %{email: "email@test.com", role: "user", password: "password1"}
  @valid_account_attrs %{
    "email" => "test@email.com",
    "password" => "Password1",
    "communication_mode" => "email"
  }
  @invalid_attrs %{}

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

  describe "create_account" do
    test "creates new account" do
      assert {:ok, user} = User.create_account(@valid_account_attrs)
      assert user.id != nil
    end

    test "removes non digits from phone number input" do
      assert {:ok, user} =
               User.create_account(
                 Map.merge(@valid_account_attrs, %{
                   "communication_mode" => "sms",
                   "phone_number" => "555-555-1234"
                 })
               )

      assert user.phone_number == "5555551234"
      assert user.id != nil
    end
  end

  describe "update_account" do
    test "updates account" do
      user = insert(:user)

      assert {:ok, user} =
               User.update_account(
                 user,
                 %{
                   "phone_number" => "5550000000",
                   "communication_mode" => "sms",
                   "accept_tnc" => "true"
                 },
                 user.id
               )

      assert user.phone_number == "5550000000"
      assert user.communication_mode == "sms"
    end

    test "opts in phone number when phone number changed" do
      user = insert(:user)

      assert {:ok, _} =
               User.update_account(
                 user,
                 %{"phone_number" => "5550000000", "accept_tnc" => "true"},
                 user.id
               )

      assert_received {:opt_in_phone_number, %{"phoneNumber" => "5550000000"}}
    end

    test "does not opt in phone number when phone number not changed" do
      user = insert(:user)
      assert {:ok, _} = User.update_account(user, %{}, user.id)
      refute_received {:opt_in_phone_number, _}
    end

    test "does not update account" do
      user = insert(:user)

      assert {:error, changeset} =
               User.update_account(
                 user,
                 %{"phone_number" => "not a phone number", "communication_mode" => "sms"},
                 user.id
               )

      refute changeset.valid?
    end

    test "does not update phone number when not accepting terms and conditions" do
      user = insert(:user)

      assert {:error, changeset} =
               User.update_account(
                 user,
                 %{"phone_number" => "8888888888", "communication_mode" => "sms"},
                 user.id
               )

      refute changeset.valid?
    end
  end

  describe "create_account_changeset" do
    defp create_changeset(%{} = attributes) do
      User.create_account_changeset(%User{}, Map.merge(@valid_account_attrs, attributes))
    end

    test "is valid with valid params" do
      assert create_changeset(%{}).valid?
    end

    test "is valid with password containing special characters and at least 6 characters" do
      assert create_changeset(%{"password" => "P@ssword"}).valid?
    end

    test "is invalid with password that is too short" do
      refute create_changeset(%{"password" => "P@ss1"}).valid?
    end

    test "is invalid with password that does not contain a digit or special character" do
      refute create_changeset(%{"password" => "Password"}).valid?
    end

    test "is invalid with an email that does not contain an @" do
      refute create_changeset(%{"email" => "emailatexample.com"}).valid?
    end

    test "is invalid with an email that is missing the TLD" do
      refute create_changeset(%{"email" => "email@example"}).valid?
    end

    test "is invalid with an email that has a stray space in it" do
      refute create_changeset(%{"email" => "email @example.com"}).valid?
    end

    test "is invalid when whole string is not a valid email" do
      refute create_changeset(%{"email" => "has a@valid.email substring"}).valid?
    end

    test "trims leading and trailing spaces from email" do
      leading = create_changeset(%{"email" => " email@example.com"})
      trailing = create_changeset(%{"email" => "email@example.com "})

      assert leading.valid?
      assert leading.changes.email == "email@example.com"
      assert trailing.valid?
      assert trailing.changes.email == "email@example.com"
    end

    test "if communication_mode is sms, will validate phone number" do
      changeset =
        create_changeset(%{
          "phone_number" => "2342342344",
          "communication_mode" => "sms"
        })

      assert changeset.changes.phone_number == "2342342344"
      assert changeset.valid?
    end
  end

  describe "set_email_rejection/2" do
    test "sets a user's email rejection status and disables notifications" do
      user = insert(:user, communication_mode: "email", email_rejection_status: nil)

      {:ok, user} = User.set_email_rejection(user, "bounce")

      assert %{communication_mode: "none", email_rejection_status: "bounce"} = user
      assert %{event: "update", origin: "email-rejection"} = PaperTrail.get_version(user)
    end

    test "only allows valid rejection statuses to be set" do
      user = insert(:user)

      {:error, changeset} = User.set_email_rejection(user, "invalid")

      assert %{email_rejection_status: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "unset_email_rejection" do
    test "unsets a user's email rejection status and enables notifications" do
      user = insert(:user, communication_mode: "none", email_rejection_status: "bounce")

      {:ok, user} = User.unset_email_rejection(user)

      assert %{communication_mode: "email", email_rejection_status: nil} = user
      assert %{event: "update", origin: "email-unrejection"} = PaperTrail.get_version(user)
    end
  end

  describe "set_sms_opted_out" do
    test "sets users as opted out of SMS by phone number" do
      %{id: id1} = insert(:user, communication_mode: "sms", phone_number: "5555551234")
      %{id: id2} = insert(:user, communication_mode: "sms", phone_number: "5555556789")

      {:ok, %{^id1 => user1, ^id2 => user2}} =
        User.set_sms_opted_out(["5555551234", "5555556789"])

      assert user1.phone_number == nil
      assert user1.sms_opted_out_at != nil
      assert user1.communication_mode == "none"
      assert user2.phone_number == nil
      assert user2.sms_opted_out_at != nil
      assert user2.communication_mode == "none"
    end

    test "doesn't do anything if no phone numbers are passed" do
      assert {:ok, %{}} = User.set_sms_opted_out([])
    end
  end

  describe "get/1" do
    test "returns a user if present" do
      user = insert(:user)
      assert User.get(user.id) == user
    end

    test "returns nil if no matching user" do
      bad_id = UUID.uuid4()
      assert User.get(bad_id) == nil
    end
  end

  describe "for_email/1" do
    test "returns a user if present" do
      user = insert(:user)
      assert user == User.for_email(user.email)
    end

    test "disregards the case of the email" do
      user = insert(:user, email: "testemail@example.com")
      assert user == User.for_email("TestEmail@example.com")
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
