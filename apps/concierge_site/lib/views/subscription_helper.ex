defmodule ConciergeSite.SubscriptionHelper do
  @moduledoc """
  Functions used across subscription views
  """

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
end
