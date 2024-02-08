defmodule AlertProcessor.RepoTest do
  use AlertProcessor.DataCase, async: true
  alias AlertProcessor.Repo
  import Test.Support.Helpers

  defmodule FakeAwsRds do
    def generate_db_auth_token(_, _, _, _) do
      "iam_token"
    end
  end

  describe "before_connect/1" do
    test "generates RDS IAM auth token" do
      reassign_env(:alert_processor, :aws_rds_mod, FakeAwsRds)

      config =
        []
        |> Keyword.merge(username: "u", hostname: "h", port: 4000)
        |> Repo.before_connect()

      assert {:ok, "iam_token"} = Keyword.fetch(config, :password)
    end
  end
end
