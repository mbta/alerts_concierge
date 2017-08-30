defmodule ConciergeSite.Admin.SubscriberView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.User
  alias Calendar.Strftime

  @spec account_status(User.t) :: String.t
  def account_status(%User{encrypted_password: ""}), do: "Disabled"
  def account_status(%User{encrypted_password: nil}), do: "Disabled"
  def account_status(%User{}), do: "Active"

  def email_is_default?(user) do
    is_nil(user.phone_number)
  end

  def blackout_period(%User{do_not_disturb_start: nil, do_not_disturb_end: nil}), do: "N/A"
  def blackout_period(%User{do_not_disturb_start: dnd_start, do_not_disturb_end: dnd_end}) do
    [
      Strftime.strftime!(dnd_start, "%I:%M %p"),
      " to ",
      Strftime.strftime!(dnd_end, "%I:%M %p")
    ]
  end

  def vacation_period(%User{vacation_start: nil, vacation_end: nil}), do: "N/A"
  def vacation_period(%User{vacation_start: vacation_start, vacation_end: vacation_end}) do
    if DateTime.compare(vacation_end, DateTime.utc_now()) == :lt do
      "N/A"
    else
      [
        Strftime.strftime!(vacation_start, "%m-%d-%Y"),
        " until ",
        Strftime.strftime!(vacation_end, "%m-%d-%Y")
      ]
    end
  end
end
