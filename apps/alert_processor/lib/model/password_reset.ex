defmodule AlertProcessor.Model.PasswordReset do
  @moduledoc """
  Data to support user password recovery
  """
  @type t :: %__MODULE__{
    id: String.t,
    user_id: String.t,
    expired_at: DateTime.t,
    redeemed_at: DateTime.t
  }

  @type id :: String.t

  use Ecto.Schema
  import Ecto.Changeset
  alias Calendar.DateTime

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "password_resets" do
    belongs_to :user, User, type: :binary_id
    field :expired_at, :utc_datetime
    field :redeemed_at, :utc_datetime

    timestamps()
  end

  @permitted_fields ~w(user_id expired_at redeemed_at)a
  @required_fields ~w(user_id expired_at)a

  @doc """
  Changeset for persisting a PasswordReset
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Changeset for redeeming a PasswordReset
  """
  def redeem_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_not_already_expired()
    |> validate_not_already_redeemed()
    |> put_change(:redeemed_at, DateTime.now_utc())
  end

  defp validate_not_already_expired(changeset) do
    if DateTime.before?(changeset.data.expired_at, DateTime.now_utc()) do
      add_error(changeset, :expired_at, "Password Reset has expired.")
    else
      changeset
    end
  end

  defp validate_not_already_redeemed(changeset) do
    if is_nil(changeset.data.redeemed_at) do
      changeset
    else
      add_error(changeset, :redeemed_at, "Password Reset has already been redeemed.")
    end
  end
end
