defmodule ConciergeSite.Admin.AdminsControllerTest do
  use ConciergeSite.ConnCase, async: true

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User

  setup %{conn: conn} do
    admin = insert(:user, role: "admin")
    {:ok, admin: admin, conn: guardian_login(admin, conn)}
  end

  describe "index/2" do
    test "lists admins", %{admin: %{email: email}, conn: conn} do
      resp = conn |> get(admin_admins_path(conn, :index)) |> html_response(200)

      assert resp =~ email
    end
  end

  describe "create/2" do
    test "grants admin privileges", %{conn: conn} do
      %{id: id, email: email} = insert(:user, role: "user")

      conn = post(conn, admin_admins_path(conn, :create, email: email))

      assert redirected_to(conn) =~ admin_admins_path(conn, :index)
      assert %{role: "admin"} = Repo.get!(User, id)
    end
  end

  describe "delete/2" do
    test "revokes admin privileges", %{conn: conn} do
      %{id: id} = insert(:user, role: "admin")

      conn = delete(conn, admin_admins_path(conn, :delete, id))

      assert redirected_to(conn) =~ admin_admins_path(conn, :index)
      assert %{role: "user"} = Repo.get!(User, id)
    end
  end
end
