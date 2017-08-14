defmodule ConciergeSite.MyAccountView do
  use ConciergeSite.Web, :view
  import ConciergeSite.TimeHelper, only: [travel_time_options: 0]
  alias AlertProcessor.Model.User

  @spec sms_messaging_checked?(User.t) :: boolean
  def sms_messaging_checked?(user) do
    !is_nil(user.phone_number)
  end

  @spec do_not_disturb_checked?(User.t) :: boolean
  def do_not_disturb_checked?(user) do
    !(is_nil(user.do_not_disturb_start) and is_nil(user.do_not_disturb_end))
  end

  @spec do_not_disturb_start_selected_value(User.t) :: String.t
  def do_not_disturb_start_selected_value(user) do
    if is_nil(user.do_not_disturb_start) do
      "22:00:00"
    else
      Calendar.Strftime.strftime!(user.do_not_disturb_start, "%H:%M:%S")
    end
  end

  @spec do_not_disturb_end_selected_value(User.t) :: String.t
  def do_not_disturb_end_selected_value(user) do
    if is_nil(user.do_not_disturb_start) do
      "07:00:00"
    else
      Calendar.Strftime.strftime!(user.do_not_disturb_end, "%H:%M:%S")
    end
  end
end
