defmodule AlertProcessor.SmsOptOutWorkerTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  import ExUnit.CaptureLog
  alias AlertProcessor.Model.User
  alias AlertProcessor.SmsOptOutWorker

  setup do
    # Required due to Lock using a spawned process
    Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :auto)

    on_exit(fn ->
      Repo.delete_all(PaperTrail.Version)
      Repo.delete_all(User)
    end)
  end

  test "fetches list of opted-out phone numbers and opts out the corresponding users" do
    user = insert(:user, phone_number: "9999999999")

    SmsOptOutWorker.process_opt_outs()

    assert_received {:list_phone_numbers_opted_out, _}
    reloaded_user = Repo.one(from(u in User, where: u.id == ^user.id))
    assert reloaded_user.phone_number == nil
    assert reloaded_user.sms_opted_out_at != nil
    assert reloaded_user.communication_mode == "none"
  end

  test "doesn't update users with phone numbers not in the list" do
    user = insert(:user, phone_number: "5555551234")

    SmsOptOutWorker.process_opt_outs()

    assert_received {:list_phone_numbers_opted_out, _}
    reloaded_user = Repo.one(from(u in User, where: u.id == ^user.id))
    assert reloaded_user.phone_number == "5555551234"
  end

  test "handles errors when fetching the opt-out list" do
    # in `ExAws.Mock`, using "error" as a `nextToken` results in an error
    result = SmsOptOutWorker.fetch_opted_out_list("error", ["5555551234"])
    assert {:error, {1, {:http_error, 400, _}}} = result
  end

  test "skips processing if another instance is already processing" do
    test_pid = self()

    spawn_link(fn ->
      AlertProcessor.Lock.acquire(SmsOptOutWorker, fn :ok ->
        send(test_pid, :acquired)
        Process.sleep(:infinity)
      end)
    end)

    # Wait for above process to get the lock, otherwise the real worker might get it first
    assert_receive :acquired

    logs = capture_log(&SmsOptOutWorker.process_opt_outs/0)

    assert logs =~ "SmsOptOutWorker event=skipped"
  end
end
