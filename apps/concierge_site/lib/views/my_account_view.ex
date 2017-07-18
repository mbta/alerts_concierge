defmodule ConciergeSite.MyAccountView do
  use ConciergeSite.Web, :view
  import ConciergeSite.TimeHelper, only: [travel_time_options: 0]
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.User}

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
      "23:00:00"
    else
      time_option_local_strftime(user.do_not_disturb_start)
    end
  end

  @spec do_not_disturb_end_selected_value(User.t) :: String.t
  def do_not_disturb_end_selected_value(user) do
    if is_nil(user.do_not_disturb_start) do
      "06:00:00"
    else
      time_option_local_strftime(user.do_not_disturb_end)
    end
  end

  defp time_option_local_strftime(timestamp) do
    timestamp
    |> DateTimeHelper.utc_time_to_local()
    |> Calendar.Strftime.strftime!("%H:%M:%S")
  end
end
