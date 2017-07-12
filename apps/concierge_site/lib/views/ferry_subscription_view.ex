defmodule ConciergeSite.FerrySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper,
    only: [atomize_keys: 1, progress_link_class: 3, travel_time_options: 0]

  @disabled_progress_bar_links %{trip_info: [:trip_info, :ferry, :preferences],
  ferry: [:ferry, :preferences],
  preferences: [:preferences]}

  defdelegate progress_step_classes(page, step), to: ConciergeSite.SubscriptionViewHelper

  def progress_link_class(page, step), do: progress_link_class(page, step, @disabled_progress_bar_links)

  @doc """
  Provide description text for Trip Info page based on which trip type selected
  """
  @spec trip_info_description(any) :: String.t
  def trip_info_description(:one_way) do
    "Please note: We will only send you alerts about service updates that affect your origin and destination stations."
  end
  def trip_info_description(:round_trip) do
    [
      :one_way |> trip_info_description |> String.trim_trailing("."),
      ", in both directions."
    ]
  end
  def trip_info_description(_trip_type) do
    ""
  end
end
