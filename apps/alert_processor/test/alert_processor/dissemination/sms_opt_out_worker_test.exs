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

  test "opts out proper users" do
    a = insert(:user, phone_number: "8675309")
    b = insert(:user, phone_number: "1234567")

    {opted_out_numbers, untouched_count, error_count} = SmsOptOutWorker.process_opt_outs()
    assert opted_out_numbers == [a.phone_number]
    assert untouched_count == 1
    assert error_count == 0

    assert_received {:check_if_phone_number_is_opted_out, _}
    assert_received {:check_if_phone_number_is_opted_out, _}

    a_ = Repo.one(from(u in User, where: u.id == ^a.id))
    assert a_.phone_number == nil
    assert a_.sms_opted_out_at != nil
    assert a_.communication_mode == "none"

    b_ = Repo.one(from(u in User, where: u.id == ^b.id))
    assert b_.phone_number != nil
  end

  test "handles errors" do
    insert(:user, phone_number: "816613")

    {opted_out_numbers, untouched_count, error_count} = SmsOptOutWorker.process_opt_outs()
    assert opted_out_numbers == []
    assert untouched_count == 0
    assert error_count == 1
  end

  test "ignores null numbers" do
    a = insert(:user, phone_number: "8675309")
    insert(:user, phone_number: nil)

    {opted_out_numbers, untouched_count, error_count} = SmsOptOutWorker.process_opt_outs()
    assert opted_out_numbers == [a.phone_number]
    assert untouched_count == 0
    assert error_count == 0
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
