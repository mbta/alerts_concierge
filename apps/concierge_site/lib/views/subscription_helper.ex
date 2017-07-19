defmodule ConciergeSite.SubscriptionHelper do
  @moduledoc """
  Functions used across subscription views
  """
  use Phoenix.HTML
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Helpers.StringHelper

  @doc """
  Takes days of week of a trip and formats into a human readable manner
  """
  def joined_day_list(params) do
    params
    |> Map.take(~w(saturday sunday weekday))
    |> Enum.filter(fn {_day, value} -> value == "true" end)
    |> Enum.map(fn {day, _value} ->
        if day == "saturday" || day == "sunday" do
          String.capitalize(day)
        else
          day
        end
    end)
    |> StringHelper.or_join()
  end

  def atomize_keys(map) do
    for {k, v} <- map, do: {String.to_existing_atom(k), v}
  end

  def direction_id(subscription) do
    subscription
    |> Map.get(:informed_entities)
    |> Enum.find_value(&(&1.direction_id))
  end

   @doc """
  Provide css class to disable links within the subscription flow progress
  bar
  """
  def progress_link_class(:trip_type, _step, _disabled_links), do: "disabled-progress-link"

  def progress_link_class(page, step, disabled_links) do
    if disabled_links |> Map.get(page) |> Enum.member?(step) do
      "disabled-progress-link"
    end
  end

  @doc """
  Provide css classes for the text and circle in progress bar steps
  """
  def progress_step_classes(page, step) when (page == step) do
    %{circle: "active-circle", name: "active-page"}
  end

  def progress_step_classes(_page, _step) do
    %{}
  end

  @doc """
  Return a readable list of relevant days for a subscription
  """
  @spec relevant_days(Subscription.t) :: iolist
  def relevant_days(subscription) do
    subscription.relevant_days
    |> Enum.map(&String.capitalize(Atom.to_string(&1)))
    |> Enum.intersperse("s, ")
    |> Kernel.++(["s"])
  end

  @doc """
  conver params into keylist to be able to pass back to previous forms
  """
  @spec do_query_string_params(map | nil, [String.t]) :: [any]
  def do_query_string_params(nil, _), do: []
  def do_query_string_params(params, param_names) when is_list(param_names) do
    relevant_params = Map.take(params, param_names)
    for param <- atomize_keys(relevant_params) do
      param
    end
  end

  @doc """
  constructs list of hidden inputs to pass along relevant parameters to next or previous step
  via post request
  """
  @spec do_hidden_form_inputs(map | nil, [String.t]) :: [any]
  def do_hidden_form_inputs(nil, _), do: []
  def do_hidden_form_inputs(params, param_names) when is_list(param_names) do
    relevant_params = Map.take(params, param_names)
    for param <- atomize_keys(relevant_params) do
      hidden_form_input(param)
    end
  end

  defp hidden_form_input({param_name, param_value}) when is_list(param_value) do
    for trip_number <- param_value do
      tag(:input, type: "hidden", name: "subscription[#{param_name}][]", value: trip_number)
    end
  end
  defp hidden_form_input({param_name, param_value}) do
    tag(:input, type: "hidden", name: "subscription[#{param_name}]", value: param_value)
  end
end
