defmodule ConciergeSite.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ConciergeSite.Router.Helpers

      # The default endpoint for testing
      @endpoint ConciergeSite.Endpoint

      # Import ExMachina Factories
      import AlertProcessor.Factory

      def guardian_login(user, conn) do
        conn
        |> bypass_through(ConciergeSite.Router, [:browser])
        |> get("/")
        |> ConciergeSite.Guardian.Plug.sign_in(
          user,
          %{
            logout_uri: "http://oidc.example/end_session_uri"
          }
        )
        |> send_resp(200, "Flush the session")
        |> recycle()
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AlertProcessor.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
