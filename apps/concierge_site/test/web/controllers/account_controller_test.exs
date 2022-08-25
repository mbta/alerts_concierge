defmodule ConciergeSite.AccountControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.Model.{Notification, Subscription, Trip, User}
  alias AlertProcessor.Repo

  test "new/4", %{conn: conn} do
    conn = get(conn, account_path(conn, :new))
    assert html_response(conn, 200) =~ "Sign up"
  end

  test "POST /account", %{conn: conn} do
    params = %{
      "user" => %{"password" => "Password1!", "email" => "test@test.com "},
      "g-recaptcha-response" => "valid_response"
    }

    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/account/options"
  end

  test "POST /account bad password", %{conn: conn} do
    params = %{
      "user" => %{"password" => "password", "email" => "test@test.com"},
      "g-recaptcha-response" => "valid_response"
    }

    conn = post(conn, account_path(conn, :create), params)

    assert html_response(conn, 200) =~ "Password must contain at least one number or symbol."
  end

  test "POST /account bad email", %{conn: conn} do
    params = %{
      "user" => %{"password" => "password1!", "email" => "test"},
      "g-recaptcha-response" => "valid_response"
    }

    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "enter a valid email"
  end

  test "POST /account empty values", %{conn: conn} do
    params = %{
      "user" => %{"password" => "", "email" => ""},
      "g-recaptcha-response" => "valid_response"
    }

    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Password is required"
    assert html_response(conn, 200) =~ "Email is required"
  end

  test "POST /account bad recaptcha", %{conn: conn} do
    params = %{
      "user" => %{"password" => "Password1!", "email" => "test@test.com "},
      "g-recaptcha-response" => "invalid_response"
    }

    conn = post(conn, account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "reCAPTCHA validation error"
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
      accept_tnc: "true",
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
    assert html_response(conn, 200) =~ "You must consent to these terms to receive SMS alerts."
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
        accept_tnc: "true",
        email: "test@test.com "
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

    test "POST /account/edit error must accept terms and conditions", %{conn: conn} do
      user = insert(:user, phone_number: nil)

      user_params = %{
        communication_mode: "sms",
        phone_number: "8888888888"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update), %{user: user_params})

      assert html_response(conn, 200) =~ "You must consent to these terms to receive SMS alerts."
    end
  end

  describe "edit page flash" do
    defp account_edit_html(conn, user) do
      user
      |> guardian_login(conn)
      |> get(account_path(conn, :edit))
      |> html_response(200)
      |> String.replace(~r/\s+/, " ")
    end

    @alerts_disabled_text "Alerts are disabled for your account"
    @email_bounced_text "We encountered an error trying to deliver email"
    @email_complaint_text "We received a spam report or other complaint"
    @sms_disabled_text "Text message delivery is disabled"
    @sms_frozen_text "we can’t send you any further text messages"
    @sms_opted_out_text "opted out of text message alerts"

    test "explains alerts being disabled when inside the SMS freeze window", %{conn: conn} do
      user = insert(:user, communication_mode: "none", sms_opted_out_at: DateTime.utc_now())

      html = account_edit_html(conn, user)

      assert html =~ @alerts_disabled_text
      assert html =~ @sms_opted_out_text
      assert html =~ @sms_frozen_text
    end

    test "explains alerts being disabled when outside the SMS freeze window", %{conn: conn} do
      user =
        insert(:user,
          communication_mode: "none",
          sms_opted_out_at: DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * -31)
        )

      html = account_edit_html(conn, user)

      assert html =~ @alerts_disabled_text
      assert html =~ @sms_opted_out_text
      refute html =~ @sms_frozen_text
    end

    test "explains SMS alerts being frozen when email delivery is enabled", %{conn: conn} do
      user = insert(:user, communication_mode: "email", sms_opted_out_at: DateTime.utc_now())

      html = account_edit_html(conn, user)

      refute html =~ @alerts_disabled_text
      assert html =~ @sms_disabled_text
      assert html =~ @sms_opted_out_text
      assert html =~ @sms_frozen_text
    end

    test "does not warn when email is enabled and outside the freeze window", %{conn: conn} do
      user =
        insert(:user,
          communication_mode: "email",
          sms_opted_out_at: DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * -31)
        )

      html = account_edit_html(conn, user)

      refute html =~ @alerts_disabled_text
      refute html =~ @sms_disabled_text
    end

    test "explains alerts being disabled due to an email bounce or complaint", %{conn: conn} do
      bounced_user = insert(:user, communication_mode: "none", email_rejection_status: "bounce")

      complained_user =
        insert(:user, communication_mode: "none", email_rejection_status: "complaint")

      bounced_html = account_edit_html(conn, bounced_user)
      complained_html = account_edit_html(conn, complained_user)

      assert bounced_html =~ @alerts_disabled_text
      assert bounced_html =~ @email_bounced_text
      assert complained_html =~ @alerts_disabled_text
      assert complained_html =~ @email_complaint_text
    end

    test "explains alerts being disabled for an unknown reason", %{conn: conn} do
      user = insert(:user, communication_mode: "none")

      html = account_edit_html(conn, user)

      assert html =~ @alerts_disabled_text
    end

    test "does not explain anything if there is nothing to explain", %{conn: conn} do
      user = insert(:user, communication_mode: "email")

      html = account_edit_html(conn, user)

      refute html =~ @alerts_disabled_text
      refute html =~ @sms_disabled_text
      refute html =~ @sms_opted_out_text
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
      user = insert(:user, encrypted_password: Bcrypt.hash_pwd_salt("Password1!"))

      user_params = %{current_password: "Password1!", password: "Password2!"}

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update_password), %{user: user_params})

      assert html_response(conn, 302) =~ "/trips"
    end

    test "POST /password/edit no match error", %{conn: conn} do
      user = insert(:user, encrypted_password: Bcrypt.hash_pwd_salt("Password1!"))

      user_params = %{current_password: "Password3!", password: "Password2!"}

      conn =
        user
        |> guardian_login(conn)
        |> post(account_path(conn, :update_password), %{user: user_params})

      assert html_response(conn, 200) =~ "Current password is incorrect"
    end
  end

  test "POST /password/edit validation error", %{conn: conn} do
    user = insert(:user, encrypted_password: Bcrypt.hash_pwd_salt("Password1!"))

    user_params = %{current_password: "Password1!", password: "Password"}

    conn =
      user
      |> guardian_login(conn)
      |> post(account_path(conn, :update_password), %{user: user_params})

    assert html_response(conn, 200) =~ "New password format is incorrect"
  end

  describe "account delete" do
    test "DELETE /account/delete", %{conn: conn} do
      user = insert(:user, email: "email1@example.com")
      # generate a PaperTrail version for the user so we can ensure that's deleted too
      User.update_account(user, %{email: "email2@example.com"}, user)
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        user_id: user.id,
        trip_id: trip.id,
        type: :cr,
        origin: "place-DB-0095",
        destination: "place-DB-2265",
        route: "CR-Fairmount"
      })

      insert(:notification, %{alert_id: "Test", status: :sent, user_id: user.id})

      conn =
        user
        |> guardian_login(conn)
        |> delete(account_path(conn, :delete))

      assert html_response(conn, 302) =~ "/deleted"
      # ensure all associated data was deleted
      refute Repo.one(User)
      refute Repo.one(Trip)
      refute Repo.one(Subscription)
      refute Repo.one(Notification)
      refute Repo.one(PaperTrail.Version)
    end
  end

  describe "mailchimp unsubscribe webhook for unsubscribe" do
    @secret :crypto.hash(:md5, ConfigHelper.get_string(:mailchimp_api_url, :concierge_site))
            |> Base.encode16()

    test "POST /mailchimp/update without required params", %{conn: conn} do
      conn = post(conn, account_path(conn, :mailchimp_update), %{})
      expected = %{"message" => "invalid request", "status" => "ok"}

      assert json_response(conn, 200) == expected
    end

    test "POST /mailchimp/update with wrong secret", %{conn: conn} do
      post_body = %{
        "type" => "unsubscribe",
        "data" => %{"email" => "test@test.com"},
        "secret" => "x"
      }

      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      expected = %{"status" => "ok", "message" => "skipped", "affected" => 0}

      assert json_response(conn, 200) == expected
    end

    test "POST /mailchimp/update with correct secret, unknown user", %{conn: conn} do
      post_body = %{
        "type" => "unsubscribe",
        "data" => %{"email" => "test@test.com"},
        "secret" => @secret
      }

      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      expected = %{"status" => "ok", "message" => "updated", "affected" => 0}

      assert json_response(conn, 200) == expected
    end

    test "POST /mailchimp/update with correct secret, correct user", %{conn: conn} do
      email = "unsubscribe@email.com"
      insert(:user, email: email, digest_opt_in: true)

      post_body = %{"type" => "unsubscribe", "data" => %{"email" => email}, "secret" => @secret}
      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      user = User.for_email(email)
      expected = %{"status" => "ok", "message" => "updated", "affected" => 1}

      assert json_response(conn, 200) == expected
      assert user.digest_opt_in == false
    end
  end

  describe "mailchimp unsubscribe webhook for email change" do
    @secret :crypto.hash(:md5, ConfigHelper.get_string(:mailchimp_api_url, :concierge_site))
            |> Base.encode16()

    test "POST /mailchimp/update with wrong secret", %{conn: conn} do
      post_body = %{
        "type" => "upemail",
        "data" => %{"old_email" => "test@test.com", "new_email" => "test1@test.com"},
        "secret" => "x"
      }

      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      expected = %{"status" => "ok", "message" => "skipped", "affected" => 0}

      assert json_response(conn, 200) == expected
    end

    test "POST /mailchimp/update with correct secret, unknown user", %{conn: conn} do
      post_body = %{
        "type" => "upemail",
        "data" => %{"old_email" => "unknown@test.com", "new_email" => "unknown@test.com"},
        "secret" => @secret
      }

      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      expected = %{"status" => "ok", "message" => "updated", "affected" => 0}

      assert json_response(conn, 200) == expected
    end

    test "POST /mailchimp/update with correct secret, correct user", %{conn: conn} do
      email = "change@email.com"
      new_email = "change1@email.com"
      insert(:user, email: email)

      post_body = %{
        "type" => "upemail",
        "data" => %{"old_email" => email, "new_email" => new_email},
        "secret" => @secret
      }

      conn = post(conn, account_path(conn, :mailchimp_update), post_body)
      user = User.for_email(new_email)
      expected = %{"status" => "ok", "message" => "updated", "affected" => 1}

      assert json_response(conn, 200) == expected
      assert user.email == new_email
    end
  end
end
