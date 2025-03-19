defmodule ConciergeSite.Admin.ScrController do
  use ConciergeSite.Web, :controller
  import Ecto.Query
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo

  @old_route "CR-Middleborough"
  @new_route "CR-NewBedford"
  @old_stop_id "place-MM-0356"
  @new_stop_id "place-MBS-0350"
  @new_stop_lat 41.887
  @new_stop_long -70.923209

  def index(conn, _params) do
    counts =
      Repo.all(
        from(s in Subscription,
          where: s.route == @old_route or s.route == @new_route,
          group_by: s.route,
          select: %{s.route => count(s.id)}
        )
      )
      |> Enum.reduce(%{}, &Map.merge/2)

    render(conn, "index.html",
      count_before: Map.get(counts, @old_route, 0),
      count_after: Map.get(counts, @new_route, 0)
    )
  end

  def phase1(conn, _params) do
    {:ok, flash} =
      Repo.transaction(
        fn ->
          subscriptions = get_relevant_subscriptions_by_route_and_id()

          old_subscriptions = Map.get(subscriptions, @old_route, %{})
          already_migrated_subscriptions = Map.get(subscriptions, @new_route, %{})

          new_subscriptions =
            old_subscriptions
            |> Enum.flat_map(fn {_, old_subscription} ->
              new_subscription_for_old_subscription(
                old_subscription,
                already_migrated_subscriptions
              )
              |> List.wrap()
            end)

          new_subscription_count = length(new_subscriptions)

          "Migrated #{new_subscription_count} subscriptions."
        end,
        timeout: 60_000
      )

    conn
    |> put_flash(:info, flash)
    |> redirect(to: admin_scr_path(conn, :index))
  end

  def phase2(conn, _params) do
    {:ok, flash} =
      Repo.transaction(
        fn ->
          {sub_count, _} =
            Repo.delete_all(from(s in Subscription, where: s.route == @old_route), timeout: 60_000)

          "Deleted #{sub_count} subscriptions."
        end,
        timeout: 60_000
      )

    conn
    |> put_flash(:info, flash)
    |> redirect(to: admin_scr_path(conn, :index))
  end

  @doc """
  Performs a mathematical operation on the last digit only of the given UUID,
  wrapping between 0 and f as needed.
  """
  @spec uuid_op(String.t(), (integer() -> integer())) :: String.t()
  def uuid_op(uuid, op) do
    last_digit = String.last(uuid)

    adjacent_last_digit =
      last_digit
      |> String.to_integer(16)
      |> Kernel.+(16)
      |> op.()
      |> Integer.to_string(16)
      |> String.last()
      |> String.downcase()

    String.slice(uuid, 0..(String.length(uuid) - 2)) <> adjacent_last_digit
  end

  @spec get_relevant_subscriptions_by_route_and_id :: %{
          String.t() => %{String.t() => Subscription.t()}
        }
  defp get_relevant_subscriptions_by_route_and_id do
    Repo.all(
      from(s in Subscription,
        where: s.route == @old_route or s.route == @new_route
      ),
      timeout: 60_000
    )
    |> Enum.group_by(& &1.route)
    |> Map.new(fn {route, subscriptions} ->
      {route, Map.new(subscriptions, &{&1.id, &1})}
    end)
  end

  @spec new_subscription_for_old_subscription(Subscription.t(), %{String.t() => Subscription.t()}) ::
          Subscription.t() | nil
  defp new_subscription_for_old_subscription(
         %Subscription{id: old_id} = old_subscription,
         already_migrated_subscriptions
       ) do
    new_id = old_id |> uuid_op(&(&1 + 1))

    if not Map.has_key?(already_migrated_subscriptions, new_id) do
      new_subscription = %Subscription{
        old_subscription
        | id: new_id |> Ecto.UUID.cast!(),
          route: @new_route,
          inserted_at: nil,
          updated_at: nil
      }

      new_subscription =
        if new_subscription.origin == @old_stop_id do
          %Subscription{
            new_subscription
            | origin: @new_stop_id,
              origin_lat: @new_stop_lat,
              origin_long: @new_stop_long
          }
        else
          new_subscription
        end

      new_subscription =
        if new_subscription.destination == @old_stop_id do
          %Subscription{
            new_subscription
            | destination: @new_stop_id,
              destination_lat: @new_stop_lat,
              destination_long: @new_stop_long
          }
        else
          new_subscription
        end

      new_subscription
      |> Repo.insert!()
    end
  end
end
