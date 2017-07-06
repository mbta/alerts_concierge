defmodule ConciergeSite.AmenitySubscriptionControllerTest do
  use ConciergeSite.ConnCase

  alias AlertProcessor.{Model.Subscription, Repo}

  describe "authorized" do
    setup :insert_user

    test "GET /subscriptions/amenities/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/amenities/new")

      assert html_response(conn, 200) =~ "Create New Subscription"
    end

    test "POST /subscriptions/amenities/add_station appends station to list", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => "",
        "station" => route_id
      }}
      conn = conn
      |> post("/subscriptions/amenities/add_station", params)

      expected = "<button formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\" type=\"submit\">\nForest Hills  </button>"

      assert html_response(conn, 200) =~ expected
    end

    test "POST /subscriptions/amenities/add_station does not append duplicates", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => "",
        "station" => route_id
      }}

      post(conn, "/subscriptions/amenities/add_station", params)

      params = %{"subscription" => %{
        "stops" => route_id,
        "station" => route_id
      }}

      conn = conn
      |> post("/subscriptions/amenities/add_station", params)

      expected = ~r/<button formaction=\"\/subscriptions\/amenities\/remove_station\/Forest%20Hills\" type=\"submit\">\nForest Hills  <\/button>/
      result = html_response(conn, 200)
      number_of_matches = length(Regex.scan(expected, result))

      assert number_of_matches == 1
    end

    test "POST /subscriptions/amenities/remove_station removes station from list", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => route_id
      }}

      conn = conn
      |> post("/subscriptions/amenities/remove_station/#{route_id}", params)

      station_link = "<button formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\" type=\"submit\">\nForest Hills  </button>"

      refute html_response(conn, 200) =~ station_link
    end

    test "POST /subscriptions/amenities with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => "North Quincy,Forest Hills",
        "amenities" => ["elevator"],
        "relevant_days" => ["saturday"],
        "routes" => ["blue"]
      }}

      conn = conn
      |> post("/subscriptions/amenities", params)

      subscriptions = Repo.all(Subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
    end

    test "POST /subscriptions/amenities with invalid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => "",
        "amenities" => [],
        "relevant_days" => [],
        "routes" => []
      }}

      conn = conn
      |> post("/subscriptions/amenities", params)

      assert html_response(conn, 302) =~ "/subscriptions/amenities/new"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/amenities/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/amenities/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(%{conn: c}) do
    conn = :user
    |> insert()
    |> guardian_login(c)
    {:ok, [conn: conn]}
  end
end
