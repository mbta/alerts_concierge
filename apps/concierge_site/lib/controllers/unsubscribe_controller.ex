defmodule ConciergeSite.UnsubscribeController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.Trip
  @thirty_days_in_seconds 2_592_000

  def update(conn, %{"id" => encrypted_user_id}) do
    # We're not using a separate salt here because we're not
    # encrypting passwords and don't need the extra security
    {:ok, user_id} =
      Plug.Crypto.decrypt(conn.secret_key_base, conn.secret_key_base, encrypted_user_id,
        max_age: @thirty_days_in_seconds
      )

    Trip.get_trips_by_user(user_id)
    |> Enum.each(&Trip.pause(&1, user_id))

    json(conn, %{status: "ok"})
  end
end
