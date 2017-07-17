defmodule ConciergeSite.Subscriptions.FerryParams do
  @moduledoc """
  Functions for processing user input during the create ferry subscription flow
  """

  import ConciergeSite.Subscriptions.ParamsValidator
  alias AlertProcessor.Subscription.FerryMapper

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_origin()
      |> validate_presence_of_destination()
      |> validate_origin_destination_pair()
      |> validate_travel_day()

    case errors do
      [] ->
        :ok
      errors ->
        {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_presence_of_origin({params, errors}) do
    if params["origin"] == "" do
      {params, ["Origin is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_presence_of_destination({params, errors}) do
    if params["destination"] == "" do
      {params, ["Destination is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_origin_destination_pair({params, errors}) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days} = params
    case FerryMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days)) do
      {:ok, _} ->
        {params, errors}
      _ ->
        {params, ["Please select a valid origin and destination combination." | errors]}
    end
  end

  defp validate_travel_day({params, errors}) do
    if Enum.member?(["weekday", "saturday", "sunday"], String.downcase(params["relevant_days"])) do
      {params, errors}
    else
      {params, ["A travel day option must be selected." | errors]}
    end
  end
end
