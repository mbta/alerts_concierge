defmodule ConciergeSite.BasePolicyTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias ConciergeSite.BasePolicy

  test "Base policy authorizes all actions for admin" do
    user = insert(:user, role: "admin")

    assert BasePolicy.can?(user, :edit, %{})
    assert BasePolicy.can?(user, :create, %{})
    assert BasePolicy.can?(user, :show, %{})
    assert BasePolicy.can?(user, :delete, %{})
    assert BasePolicy.can?(user, :index, %{})
  end

  test "Base policy authorizes all actions for user" do
    user = insert(:user)

    refute BasePolicy.can?(user, :edit, %{})
    refute BasePolicy.can?(user, :create, %{})
    refute BasePolicy.can?(user, :show, %{})
    refute BasePolicy.can?(user, :delete, %{})
    refute BasePolicy.can?(user, :index, %{})
  end

  test "Base policy authorizes all actions for unauthed user" do
    user = insert(:user)

    refute BasePolicy.can?(user, :edit, %{})
    refute BasePolicy.can?(user, :create, %{})
    refute BasePolicy.can?(user, :show, %{})
    refute BasePolicy.can?(user, :delete, %{})
    refute BasePolicy.can?(user, :index, %{})
  end
end
