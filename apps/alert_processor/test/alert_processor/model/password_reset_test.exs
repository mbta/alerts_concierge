defmodule AlertProcessor.Model.PasswordResetTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Model.PasswordReset

  test "create_changeset/2 with valid parameters" do
    valid_attrs = params_with_assocs(:password_reset)
    changeset = PasswordReset.create_changeset(%PasswordReset{}, valid_attrs)
    assert changeset.valid?
  end

  test "create_changeset/2 with invalid parameters" do
    changeset = PasswordReset.create_changeset(%PasswordReset{}, %{})
    refute changeset.valid?
  end

  test "redeem_changeset/2 with a redeemable PasswordReset" do
    password_reset = insert(:password_reset)
    changeset = PasswordReset.redeem_changeset(password_reset)
    assert changeset.valid?
  end

  test "redeem_changeset/2 with an expired PasswordReset" do
    expired_at = DateTime.add(DateTime.utc_now(), -3600)
    password_reset = insert(:password_reset, expired_at: expired_at)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end

  test "redeem_changeset/2 with a redeemed PasswordReset" do
    redeemed_at = DateTime.add(DateTime.utc_now(), -3600)
    password_reset = insert(:password_reset, redeemed_at: redeemed_at)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end
end
