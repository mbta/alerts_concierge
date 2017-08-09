defmodule ConciergeSite.Admin.MyAccountView do
  use ConciergeSite.Web, :view
  import ConciergeSite.MyAccountView, only: [sms_messaging_checked?: 1]
end
