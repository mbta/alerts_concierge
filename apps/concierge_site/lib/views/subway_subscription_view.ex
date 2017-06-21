defmodule ConciergeSite.SubwaySubscriptionView do
  use ConciergeSite.Web, :view

  @typedoc """
  Possible values for trip types in Create Subscription flow
  """
  @type trip_type :: :one_way | :round_trip | :roaming

  @disabled_progress_bar_links %{trip_info: [:trip_info, :preferences],
    preferences: [:preferences]}

  @doc """
  Provide css class to disable links within the subscription flow progress
  bar
  """
  def progress_link_class(:trip_type, _step), do: "disabled-progress-link"

  def progress_link_class(page, step) do
    if @disabled_progress_bar_links |> Map.get(page) |> Enum.member?(step) do
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
  Provide description text for Trip Info page based on which trip type selected
  """

  @spec trip_info_description(trip_type) :: String.t
  def trip_info_description(:one_way) do
    "Please note: We will only send you alerts about service updates that affect your origin and destination stations."
  end

  def trip_info_description(:round_trip) do
    [
      :one_way |> trip_info_description |> String.trim_trailing("."),
      ", in both directions."
    ]
  end

  def trip_info_description(:roaming) do
    "We will send you alerts and service updates that affect all stations along your specified route."
  end

  def trip_info_description(_trip_type) do
    ""
  end

  @doc """
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options() do
    0
    |> Stream.iterate(&(&1 + 900))
    |> Stream.map(&Calendar.Time.from_second_in_day/1)
    |> Stream.map(&Calendar.Strftime.strftime!(&1, "%I:%M %p"))
    |> Enum.take(96)
  end
end
