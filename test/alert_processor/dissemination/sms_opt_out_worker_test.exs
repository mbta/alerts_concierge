defmodule MbtaServer.AlertProcessor.SmsOptOutWorkerTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.User
  alias MbtaServer.AlertProcessor.SmsOptOutWorker

  test "worker fetches list of opted out phone numbers from aws sns and update vacation time for new numbers" do
    user = insert(:user, phone_number: "+19999999999")
    {:noreply, _} = SmsOptOutWorker.handle_info(:work, [])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert :eq = DateTime.compare(reloaded_user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC"))
  end

  test "worker fetches list of opted out phone numbers from aws sns and doesnt update for numbers not in list" do
    user = insert(:user, phone_number: "+15555551234")
    {:noreply, _} = SmsOptOutWorker.handle_info(:work, [])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert reloaded_user.vacation_end == nil
  end

  test "worker fetches list of opted out phone numbers from aws sns and update vacation time for new numbers with existing state" do
    user = insert(:user, phone_number: "+19999999999")
    {:noreply, new_state} = SmsOptOutWorker.handle_info(:work, ["+12222222222", "+13333333333"])
    assert_received :list_phone_numbers_opted_out
    reloaded_user = Repo.one(from u in User, where: u.id == ^user.id)
    assert :eq = DateTime.compare(reloaded_user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC"))
    assert new_state == ["+19999999999"]
  end
end
