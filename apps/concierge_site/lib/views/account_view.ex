defmodule ConciergeSite.AccountView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User
  alias Ecto.Changeset

  def fetch_field!(changeset, field) do
    {_, value} = Changeset.fetch_field(changeset, field)
    value
  end

  def sms_frozen?(%{data: user}), do: User.inside_opt_out_freeze_window?(user)
end
