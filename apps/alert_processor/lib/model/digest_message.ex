defmodule AlertProcessor.Model.DigestMessage do
  @moduledoc """
  Representation of DigestMessage data
  """
  alias AlertProcessor.{Model.User, Model.Digest, DigestSerializer}
  defstruct [:user, :digest, :body]

  @type t :: %__MODULE__{
    user: User.t,
    digest: Digest.t,
    body: String.t
  }

  def from_digest(digest) do
    %__MODULE__{user: digest.user,
                digest: digest,
                body: DigestSerializer.serialize(digest)}
  end

end
