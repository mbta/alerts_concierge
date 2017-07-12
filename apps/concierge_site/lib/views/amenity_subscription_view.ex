defmodule ConciergeSite.AmenitySubscriptionView do
  use ConciergeSite.Web, :view

  def stringify(params) when is_list(params) do
    Enum.join(params, ",")
  end
  def stringify(p), do: p
end
