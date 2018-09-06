defmodule ConciergeSite.AccountControllerTest do
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.User, Repo}

  test "new/4", %{conn: conn} do
    conn = get(conn, account_path(conn, :new))
    assert html_response(conn, 200) =~ "Sign up"
  end

  test "POST /account", %{conn: conn} do
    params = %{"user" => %{"password" => "Password1!", "email" => "test@test.com"}}
    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/account/options"
  end

  test "POST /account bad password", %{conn: conn} do
    params = %{"user" => %{"password" => "password", "email" => "test@test.com"}}
    conn = post(conn, account_path(conn, :create), params)

    assert html_response(conn, 200) =~
             "Password must contain at least 6 characters, with one number or symbol."
  end

  test "POST /account bad email", %{conn: conn} do
    params = %{"user" => %{"password" => "password1!", "email" => "test"}}
    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "enter a valid email"
  end

  test "POST /account empty values", %{conn: conn} do
    params = %{"user" => %{"password" => "", "email" => ""}}
    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Password is required"
    assert html_response(conn, 200) =~ "Email is required"
  end

  test "GET /account/options", %{conn: conn} do
    user = insert(:user)

    conn =
      user
      |> guardian_login(conn)
      |> get(account_path(conn, :options_new))

    assert html_response(conn, 200) =~ "Customize my settings"
    assert html_response(conn, 200) =~ "How would you like to receive alerts?"
  end

  test "POST /account/options", %{conn: conn} do
    user = insert(:user, phone_number: nil)

    user_params = %{
      communication_mode: "sms",
      phone_number: "5555555555",
      digest_opt_in: false
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(account_path(conn, :options_create), %{user: user_params})

    updated_user = Repo.get(User, user.id)

    assert html_response(conn, 302) =~ "/trip/new"
    assert updated_user.phone_number == "5555555555"
    assert updated_user.digest_opt_in == false
  end

  test "POST /account/options with email", %{conn: conn} do
    user = insert(:user, phone_number: nil)

    user_params = %{
      communication_mode: "email",
      phone_number: "5555555555"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(account_path(conn, :options_create), %{user: user_params})

    updated_user = Repo.get!(User, user.id)

    assert html_response(conn, 302) =~ "/trip/new"
    assert updated_user.phone_number == nil
  end

  test "POST /account/options with errors", %{conn: conn} do
    user = insert(:user)

    user_params = %{
      communication_mode: "sms",
      phone_number: "123"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(account_path(conn, :options_create), %{user: user_params})

    assert html_response(conn, 200) =~ "Customize my settings"
    assert html_response(conn, 200) =~ "How would you like to receive alerts?"
    assert html_response(conn, 200) =~ "Phone number is not in a valid format."
  end

  describe "edit account" do
    test "GET /account/edit", %{conn: conn} do
      user = insert(:user)

      conn =
        user
        |> guardian_login(conn)
        |> get(account_path(conn, :edit))

      assert html_response(conn, 200) =~ "Settings"
    end

    test "POST /account/edit", %{conn: conn} do
      user = insert(:user, phone_number: nil)

      user_params = %{
        communication_mode: "sms",
        phone_number: "5555555555",
        email: "test@test.com"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update), %{user: user_params})

      updated_user = Repo.get!(User, user.id)

      assert html_response(conn, 302) =~ "/trips"
      assert updated_user.phone_number == "5555555555"
      assert updated_user.communication_mode == "sms"
      assert updated_user.email == "test@test.com"
    end

    test "POST /account/edit error email in use", %{conn: conn} do
      insert(:user, email: "taken@email.com")
      user = insert(:user, email: "before@email.com")

      user_params = %{
        communication_mode: "email",
        email: "taken@email.com"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update), %{user: user_params})

      assert html_response(conn, 200) =~ "Sorry, that email has already been taken"
    end

    test "POST /account/edit error invalid phone number", %{conn: conn} do
      user = insert(:user, phone_number: nil)

      user_params = %{
        communication_mode: "sms",
        phone_number: "5"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update), %{user: user_params})

      assert html_response(conn, 200) =~ "Phone number is not in a valid format"
    end
  end

  describe "update password" do
    test "GET /password/edit", %{conn: conn} do
      user = insert(:user)

      conn =
        user
        |> guardian_login(conn)
        |> get(account_path(conn, :edit_password))

      assert html_response(conn, 200) =~ "Update password"
    end

    test "POST /password/edit", %{conn: conn} do
      user = insert(:user, encrypted_password: Comeonin.Bcrypt.hashpwsalt("Password1!"))

      user_params = %{current_password: "Password1!", password: "Password2!"}

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update_password), %{user: user_params})

      assert html_response(conn, 302) =~ "/trips"
    end

    test "POST /password/edit no match error", %{conn: conn} do
      user = insert(:user, encrypted_password: Comeonin.Bcrypt.hashpwsalt("Password1!"))

      user_params = %{current_password: "Password3!", password: "Password2!"}

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update_password), %{user: user_params})

      assert html_response(conn, 200) =~ "Current password is incorrect"
    end
  end

  test "POST /password/edit validation error", %{conn: conn} do
    user = insert(:user, encrypted_password: Comeonin.Bcrypt.hashpwsalt("Password1!"))

    user_params = %{current_password: "Password1!", password: "Password"}

    conn =
      user
      |> guardian_login(conn)
      |> post(account_path(conn, :update_password), %{user: user_params})

    assert html_response(conn, 200) =~ "New password format is incorrect"
  end

  describe "account delete" do
    test "DELETE /account/delete", %{conn: conn} do
      user = insert(:user)
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        user_id: user.id,
        trip_id: trip.id,
        type: :cr,
        origin: "Readville",
        destination: "Newmarket",
        route: "CR-Fairmount"
      })

      insert(:notification, %{alert_id: "Test", status: :sent, user_id: user.id})

      conn =
        user
        |> guardian_login(conn)
        |> delete(account_path(conn, :delete))

      assert html_response(conn, 302) =~ "/deleted"
    end
  end
end
