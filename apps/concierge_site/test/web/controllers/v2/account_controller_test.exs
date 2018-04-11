defmodule ConciergeSite.V2.AccountControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.User, Repo}

  test "GET /v2/account/new", %{conn: conn} do
    conn = get(conn, v2_account_path(conn, :new))
    assert html_response(conn, 200) =~ "Create account"
  end

  test "POST /v2/account", %{conn: conn} do
    params = %{"user" => %{"password" => "Password1!", "email" => "test@test.com"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/v2/account/options"
  end

  test "POST /v2/account bad password", %{conn: conn} do
    params = %{"user" => %{"password" => "password", "email" => "test@test.com"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Password must contain one number"
  end

  test "POST /v2/account bad email", %{conn: conn} do
    params = %{"user" => %{"password" => "password1!", "email" => "test"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "enter a valid email"
  end

  test "POST /v2/account empty values", %{conn: conn} do
    params = %{"user" => %{"password" => "", "email" => ""}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "be blank"
  end

  test "GET /v2/account/options", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> get(v2_account_path(conn, :options_new))

    assert html_response(conn, 200) =~ "Customize my settings"
    assert html_response(conn, 200) =~ "How would you like to receive alerts?"
  end

  test "POST /v2/account/options", %{conn: conn} do
    user = insert(:user, phone_number: nil)

    user_params = %{
      sms_toggle: "true",
      phone_number: "5555555555",
      digest_opt_in: false
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_account_path(conn, :options_create), %{user: user_params})

    updated_user = Repo.get(User, user.id)

    assert html_response(conn, 302) =~ "/v2/trip_type"
    assert updated_user.phone_number == "5555555555"
    assert updated_user.digest_opt_in == false
  end

  test "POST /v2/account/options with email", %{conn: conn} do
    user = insert(:user, phone_number: nil)

    user_params = %{
      sms_toggle: "false",
      phone_number: "5555555555"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_account_path(conn, :options_create), %{user: user_params})

    updated_user = Repo.get!(User, user.id)

    assert html_response(conn, 302) =~ "/v2/trip_type"
    assert updated_user.phone_number == nil
  end

  test "POST /v2/account/options with errors", %{conn: conn} do
    user = insert(:user)

    user_params = %{
      sms_toggle: "true",
      phone_number: "123"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_account_path(conn, :options_create), %{user: user_params})

    assert html_response(conn, 200) =~ "Customize my settings"
    assert html_response(conn, 200) =~ "How would you like to receive alerts?"
    assert html_response(conn, 200) =~ "Phone number is not in a valid format."
  end

  describe "edit account" do
    test "GET /v2/account/edit", %{conn: conn} do
      user = insert(:user)

      conn = user
      |> guardian_login(conn)
      |> get(v2_account_path(conn, :edit))

      assert html_response(conn, 200) =~ "My account settings"
    end

    test "POST /v2/account/edit", %{conn: conn} do
      user = insert(:user, phone_number: nil)

      user_params = %{
        sms_toggle: "true",
        phone_number: "5555555555"
      }
  
      conn = user
      |> guardian_login(conn)
      |> post(v2_account_path(conn, :update), %{user: user_params})
  
      updated_user = Repo.get!(User, user.id)
  
      assert html_response(conn, 302) =~ "/v2/trips"
      assert updated_user.phone_number == "5555555555"
    end

    test "POST /v2/account/edit error", %{conn: conn} do
      user = insert(:user, phone_number: nil)

      user_params = %{
        sms_toggle: "true",
        phone_number: "5"
      }
  
      conn = user
      |> guardian_login(conn)
      |> post(v2_account_path(conn, :update), %{user: user_params})
    
      assert html_response(conn, 200) =~ "Phone number is not in a valid format"
    end
  end

  describe "update password" do
    test "GET /v2/password/edit", %{conn: conn} do
      user = insert(:user)

      conn = user
      |> guardian_login(conn)
      |> get(v2_account_path(conn, :edit_password))

      assert html_response(conn, 200) =~ "Update password"
    end

    test "POST /v2/password/edit", %{conn: conn} do
      user = insert(:user, encrypted_password: Comeonin.Bcrypt.hashpwsalt("Password1!"))

      user_params = %{current_password: "Password1!", password: "Password2!"}
  
      conn = user
      |> guardian_login(conn)
      |> post(v2_account_path(conn, :update_password), %{user: user_params})
    
      assert html_response(conn, 302) =~ "/v2/trips"
    end

    test "POST /v2/password/edit error", %{conn: conn} do
      user = insert(:user, encrypted_password: Comeonin.Bcrypt.hashpwsalt("Password1!"))

      user_params = %{current_password: "Password3!", password: "Password2!"}
  
      conn = user
      |> guardian_login(conn)
      |> post(v2_account_path(conn, :update_password), %{user: user_params})
   
      assert html_response(conn, 200) =~ "Current password is incorrect"
    end
  end

  describe "account delete" do
    test "DELETE /v2/account/delete", %{conn: conn} do
      user = insert(:user)

      conn = user
      |> guardian_login(conn)
      |> delete(v2_account_path(conn, :delete))

      assert html_response(conn, 302) =~ "/v2/deleted"
    end
  end
end
