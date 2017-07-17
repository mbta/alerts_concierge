defmodule AlertProcessor.Model.PasswordResetTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.PasswordReset
  alias Calendar.DateTime

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
    expired_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, expired_at: expired_at)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end

  test "redeem_changeset/2 with a redeemed PasswordReset" do
    redeemed_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, redeemed_at: redeemed_at)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end

  test "redeemable?/1 with a password reset that has not expired or been redeemed yet" do
    password_reset = insert(:password_reset)

    assert PasswordReset.redeemable?(password_reset)
  end

  test "redeemable?/1 with a password reset has expired" do
    expired_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, expired_at: expired_at)

    refute PasswordReset.redeemable?(password_reset)
  end

  test "redeemable?/1 with a password reset that has been redeemed"do
    redeemed_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, redeemed_at: redeemed_at)

    refute PasswordReset.redeemable?(password_reset)
  end
end
