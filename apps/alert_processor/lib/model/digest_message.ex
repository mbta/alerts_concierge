defmodule AlertProcessor.Model.DigestMessage do
  @moduledoc """
  Representation of DigestMessage data
  """
  alias AlertProcessor.{Model, DigestSerializer}
  alias Model.{Alert, Digest, DigestMessage, User}
  defstruct [:user, :digest, :body]

  @type t :: %__MODULE__{
    user: User.t,
    digest: Digest.t,
    body: [{String.t, [Alert.t]}]
  }

  def from_digest(digest) do
    %__MODULE__{user: digest.user,
                digest: digest,
                body: DigestSerializer.serialize(digest)}
  end

end
