defmodule AlertProcessor.MailerErrorMock do
  @moduledoc "Substitute for Bamboo.ApiError within AlertProcessor tests"
  defexception [:message]
end
