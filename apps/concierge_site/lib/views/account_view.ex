defmodule ConciergeSite.AccountView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User
  alias Ecto.Changeset

  defp fetch_field!(changeset, field) do
    {_, value} = Changeset.fetch_field(changeset, field)
    value
  end

  defp sms_frozen?(%{data: user}), do: User.inside_opt_out_freeze_window?(user)
end
