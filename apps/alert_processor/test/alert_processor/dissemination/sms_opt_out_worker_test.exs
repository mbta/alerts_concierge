defmodule AlertProcessor.SmsOptOutWorkerTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.User
  alias AlertProcessor.SmsOptOutWorker

  test "worker fetches list of opted out phone numbers from aws sns and removes the phone numbers from the accounts" do
    user = insert(:user, phone_number: "9999999999")
    {:noreply, _} = SmsOptOutWorker.handle_info(:work, [])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert reloaded_user.phone_number == nil
  end

  test "worker fetches list of opted out phone numbers from aws sns and doesnt update for numbers not in list" do
    user = insert(:user, phone_number: "5555551234")
    {:noreply, _} = SmsOptOutWorker.handle_info(:work, [])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert reloaded_user.phone_number == "5555551234"
  end

  test "worker fetches list of opted out phone numbers from aws sns and removes numbers for users with existing state" do
    user = insert(:user, phone_number: "9999999999")
    {:noreply, new_state} = SmsOptOutWorker.handle_info(:work, ["2222222222", "3333333333"])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert reloaded_user.phone_number == nil
    assert new_state == ["9999999999", "5555555555"]
  end
end
