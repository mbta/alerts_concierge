defmodule AlertProcessor.Authorizer.TripAuthorizer do
  alias AlertProcessor.Model.{Trip, User}

  @type authorized_response_type :: {:ok, :authorized} | {:error, :unauthorized}

  @spec authorize(Trip.t(), User.t()) :: authorized_response_type
  def authorize(%Trip{user_id: trip_user_id}, %User{id: user_id}) when trip_user_id == user_id,
    do: {:ok, :authorized}

  def authorize(_, _), do: {:error, :unauthorized}
end
