defmodule AlertProcessor.UserUpdateWorkerTest do
  use AlertProcessor.DataCase

  import AlertProcessor.Factory
  import AlertProcessor.Test.Support.Helpers

  alias AlertProcessor.Model.User
  alias AlertProcessor.UserUpdateWorker
  alias Ecto.UUID

  describe "start_link/1" do
    test "starts the server" do
      assert {:ok, _pid} = UserUpdateWorker.start_link(name: :start_link)
    end
  end

  describe "init/1" do
    test "fetches initial messages" do
      reassign_env(:alert_processor, :receive_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :delete_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :request_fn, fn _, _ -> %{} end)

      {:ok, nil} = UserUpdateWorker.init([])
      assert_receive(:fetch_message)
    end
  end

  describe "handle_info :fetch_message" do
    test "updates individual user properties" do
      user = insert(:user)
      new_phone = "5550000000"

      reassign_env(:alert_processor, :receive_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :delete_message_fn, fn _, _ -> %{} end)

      reassign_env(:alert_processor, :request_fn, fn _, _ ->
        message_body = %{
          "mbtaUuid" => user.id,
          "updates" => %{"phone_number" => "+1#{new_phone}"}
        }

        {:ok,
         %{
           body: %{
             messages: [
               %{body: Poison.encode!(message_body), receipt_handle: "MOCK_RECEIPT_HANDLE"}
             ]
           },
           status_code: 200
         }}
      end)

      refute user.phone_number == new_phone

      assert UserUpdateWorker.handle_info(:fetch_message, nil) == {:noreply, nil}

      updated_user = User.get(user.id)

      assert updated_user.phone_number == new_phone
    end

    test "updates multiple user properties" do
      user = insert(:user)
      new_phone = "5550000000"
      new_email = "email-updated@example.com"

      reassign_env(:alert_processor, :receive_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :delete_message_fn, fn _, _ -> %{} end)

      reassign_env(:alert_processor, :request_fn, fn _, _ ->
        message_body = %{
          "mbtaUuid" => user.id,
          "updates" => %{"email" => new_email, "phone_number" => "+1#{new_phone}"}
        }

        {:ok,
         %{
           body: %{
             messages: [
               %{body: Poison.encode!(message_body), receipt_handle: "MOCK_RECEIPT_HANDLE"}
             ]
           },
           status_code: 200
         }}
      end)

      refute user.email == new_email
      refute user.phone_number == new_phone

      assert UserUpdateWorker.handle_info(:fetch_message, nil) == {:noreply, nil}

      updated_user = User.get(user.id)

      assert updated_user.email == new_email
      assert updated_user.phone_number == new_phone
    end

    test "ignores updates for user properties we don't save" do
      user = insert(:user)

      reassign_env(:alert_processor, :receive_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :delete_message_fn, fn _, _ -> %{} end)

      reassign_env(:alert_processor, :request_fn, fn _, _ ->
        message_body = %{"mbtaUuid" => user.id, "updates" => %{"firstName" => "Beth"}}

        {:ok,
         %{
           body: %{
             messages: [
               %{body: Poison.encode!(message_body), receipt_handle: "MOCK_RECEIPT_HANDLE"}
             ]
           },
           status_code: 200
         }}
      end)

      assert UserUpdateWorker.handle_info(:fetch_message, nil) == {:noreply, nil}

      updated_user = User.get(user.id)

      assert updated_user == user
    end

    test "ignores updates for users that aren't in the local database" do
      reassign_env(:alert_processor, :receive_message_fn, fn _, _ -> %{} end)
      reassign_env(:alert_processor, :delete_message_fn, fn _, _ -> %{} end)

      reassign_env(:alert_processor, :request_fn, fn _, _ ->
        missing_user_id = UUID.generate()

        message_body = %{
          "mbtaUuid" => missing_user_id,
          "updates" => %{"phone_number" => "+15555555555"}
        }

        {:ok,
         %{
           body: %{
             messages: [
               %{body: Poison.encode!(message_body), receipt_handle: "MOCK_RECEIPT_HANDLE"}
             ]
           },
           status_code: 200
         }}
      end)

      assert UserUpdateWorker.handle_info(:fetch_message, nil) == {:noreply, nil}
    end
  end
end
