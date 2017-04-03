# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MbtaServer.Repo.insert!(%MbtaServer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias MbtaServer.{Repo, User}

users = [
  %User{email: "test_email1@example.com", role: "user"},
  %User{email: "test_email2@example.com", phone_number: "+15555551234", role: "user"}
]

users |> Enum.each(&Repo.insert!/1)
