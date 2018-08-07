defmodule UserMakeNotAdmin do
  @moduledoc """
  Given an email address will make a user not an admin.

  ```
  env `cat .env` mix run ./scripts/user_make_not_admin.exs --email user@example.com
  ```
  """
  alias AlertProcessor.Model.User

  def run({:make_not_admin, email}) do
    with {:ok, user} <-
           email
           |> User.for_email()
           |> User.make_not_admin() do
      IO.puts("Successfully made #{user.email} not an admin")
    else
      _ ->
        IO.puts("Something went wrong! Unable to make #{email} not an admin")
    end
  end

  def run(:exit) do
    IO.puts(
      "Pleae include an email: env `cat .env` mix run ./scripts/user_make_not_admin.exs --email user@example.com"
    )

    System.halt(1)
  end
end

opts = OptionParser.parse(System.argv(), switches: [email: :string])

case opts do
  {[email: email], _, _} -> {:make_not_admin, email}
  _ -> :exit
end
|> UserMakeNotAdmin.run()
