defmodule ConciergeSite.ImpersonateSessionPolicy do
  @moduledoc false
  alias AlertProcessor.Model.User

  def can?(admin, :impersonate_user, user) do
    User.is_admin?(admin) and not User.is_admin?(user)
  end
end
