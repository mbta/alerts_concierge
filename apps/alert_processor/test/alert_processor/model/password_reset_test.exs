defmodule AlertProcessor.Model.PasswordResetTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.PasswordReset
  alias Calendar.DateTime

  @base_attrs %{
    expired_at: DateTime.add!(DateTime.now_utc, 3600),
    redeemed_at: nil,
  }

  setup do
    user = insert(:user)
    valid_attrs = Map.put(@base_attrs, :user_id, user.id)

    {:ok, user: user, valid_attrs: valid_attrs}
  end

  test "create_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = PasswordReset.create_changeset(%PasswordReset{}, valid_attrs)
    assert changeset.valid?
  end

  test "create_changeset/2 with invalid parameters" do
    changeset = PasswordReset.create_changeset(%PasswordReset{}, %{})
    refute changeset.valid?
  end

  test "redeem_changeset/2 with a redeemable PasswordReset", %{user: user} do
    password_reset = insert(:password_reset, user_id: user.id)
    changeset = PasswordReset.redeem_changeset(password_reset)
    assert changeset.valid?
  end

  test "redeem_changeset/2 with an expired PasswordReset", %{user: user}  do
    expired_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, expired_at: expired_at, user_id: user.id)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end

  test "redeem_changeset/2 with a redeemed PasswordReset", %{user: user}  do
    redeemed_at = DateTime.subtract!(DateTime.now_utc, 3600)
    password_reset = insert(:password_reset, redeemed_at: redeemed_at, user_id: user.id)
    changeset = PasswordReset.redeem_changeset(password_reset)

    refute changeset.valid?
  end
end
