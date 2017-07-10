defmodule ConciergeSite.FerrySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper,
    only: [progress_link_class: 3]

  @disabled_progress_bar_links %{trip_info: [:trip_info, :ferry, :preferences],
  ferry: [:ferry, :preferences],
  preferences: [:preferences]}

  defdelegate progress_step_classes(page, step), to: ConciergeSite.SubscriptionViewHelper

  def progress_link_class(page, step), do: progress_link_class(page, step, @disabled_progress_bar_links)
end
