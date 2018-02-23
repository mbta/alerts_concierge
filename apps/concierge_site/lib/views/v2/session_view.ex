defmodule ConciergeSite.V2.SessionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.PasswordHelper, only: [password_regex_string: 0]
end
