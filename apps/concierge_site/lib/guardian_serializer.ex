defmodule ConciergeSite.GuardianSerializer do
  @moduledoc "Implements a token serializer/deserializer for Guardian"
  @behaviour Guardian.Serializer

  alias AlertProcessor.{Model.User, Repo}

  def for_token(%User{} = user), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
