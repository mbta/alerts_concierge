defmodule ConciergeSite.BusSubscriptionView do
  use ConciergeSite.Web, :view

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
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options() do
    Stream.iterate(0, &(&1 + 900))
    |> Stream.map(&Calendar.Time.from_second_in_day/1)
    |> Stream.map(&Calendar.Strftime.strftime!(&1, "%I:%M %p"))
    |> Enum.take(96)
  end
end
