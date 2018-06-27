defmodule SanitizeDbDump do
  @moduledoc """
  Sanitize a Postgres database dump sql file.

  NOTE: Currently we are "cheating" by relying on the knowledge that email addresses and phone numbers come one after the other in our users table definition. This lets us limit where we look for 10-digit numbers and avoid timestamps and other items that aren't actually phone numbers but look the same.

  To dump from production, sanitize, and load into dev locally:

  ```
  PGPASSWORD=<PROD PASSWORD> pg_dump --host=alerts-concierge-prod.cw84s0ixvuei.us-east-1.rds.amazonaws.com --port=5432 --username=alerts_concierge --dbname=alerts_concierge_prod --table=users --table=trips --table=subscriptions --no-owner --data-only | elixir ./scripts/sanitize_db_dump.exs | psql -d alert_concierge_dev
  ```
  """
  
  def run() do
    :stdio
    |> IO.stream(:line)
    |> Stream.map(&sanitize_an_email_addresses_followed_by_a_phone_number/1)
    |> Stream.map(&sanitize_an_email_addresses_followed_by_null/1)
    |> Enum.each(&IO.write(&1))
  end

  def sanitize_an_email_addresses_followed_by_a_phone_number(line) do
    # Email address regex
    ~r/[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+\h[0-9]{10}/
    |> Regex.replace(line, "#{mock_email()}\t5555555555")
  end

  def sanitize_an_email_addresses_followed_by_null(line) do
    # Email address regex
    ~r/[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+\h\\N/
    |> Regex.replace(line, "#{mock_email()}\t\\N")
  end

  defp mock_email() do
    chars = String.split("abcdefghijklmnopqrstuvwxyz0123456789", "")
    address = Enum.reduce((1..10), [], fn (_i, acc) ->
      [Enum.random(chars) | acc]
    end) |> Enum.join("")
    "#{address}@example.com"
  end
end

SanitizeDbDump.run()
