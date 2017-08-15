defmodule ConciergeSite.Admin.SubscriberView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.User

  @spec account_status(User.t) :: String.t
  def account_status(%User{encrypted_password: ""}), do: "Disabled"
  def account_status(%User{encrypted_password: nil}), do: "Disabled"
  def account_status(%User{}), do: "Active"

  def email_is_default?(user) do
    is_nil(user.phone_number)
  end
end
