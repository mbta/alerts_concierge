defmodule ConciergeSite.AccountControllerTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test

  describe "valid params" do
    test "creates user", %{conn: conn} do
      params = %{"user" => %{
        "email" => "test@email.com",
        "password" => "password1",
        "password_confirmation" => "password1",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "5551234567",
        "amber_alert_opt_in" => "false"
      }}

      conn = post(conn, "/account", params)
      assert html_response(conn, 302) =~ "/my-subscriptions"
    end

    test "sends account confirmation sms", %{conn: conn} do
      params = %{"user" => %{
        "email" => "test@email.com",
        "password" => "password1",
        "password_confirmation" => "password1",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "5551234567",
        "amber_alert_opt_in" => "false"
      }}

      post(conn, "/account", params)
      assert_received :publish
    end

    test "sends account confirmation email for user without phone number", %{conn: conn} do
       params = %{"user" => %{
        "email" => "test@email.com",
        "password" => "password1",
        "password_confirmation" => "password1",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "",
        "amber_alert_opt_in" => "false"
      }}

      post(conn, "/account", params)

      assert_delivered_with(to: [{nil, "test@email.com"}])
    end
  end

  describe "invalid params"do
    test "errors", %{conn: conn} do
      params = %{"user" => %{
        "email" => "",
        "password" => "",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "5551234567",
        "amber_alert_opt_in" => "false"
      }}

      conn = post(conn, "/account", params)
      response = html_response(conn, 200)

      assert response =~ "Password and password confirmation did not match."
      assert response =~ "can&#39;t be blank"
    end

    test "user cannot create an account using email that has already been taken", %{conn: conn} do
      insert(:user, email: "test@example.com")

      params = %{"user" => %{
        "email" => "TEST@example.com",
        "password" => "password1",
        "password_confirmation" => "password1",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "5551234567",
        "amber_alert_opt_in" => "false"
      }}

      conn = post(conn, "/account", params)
      response = html_response(conn, 200)

      assert response =~ "Sorry, that email has already been taken."
    end
  end
end
