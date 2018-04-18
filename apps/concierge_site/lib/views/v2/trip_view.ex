defmodule ConciergeSite.V2.TripView do
  use ConciergeSite.Web, :view
  import ConciergeSite.Helpers.MailHelper, only: [feedback_url: 0]
end
