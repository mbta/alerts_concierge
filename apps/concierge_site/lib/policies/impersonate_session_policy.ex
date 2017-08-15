defmodule ConciergeSite.ImpersonateSessionPolicy do
  alias AlertProcessor.Model.User

  def can?(admin, :impersonate_user, user) do
    User.is_admin?(admin) and not User.is_admin?(user)
  end
  
  def can?(%User{}, :impersonate_user, %User{}), do: false
end
