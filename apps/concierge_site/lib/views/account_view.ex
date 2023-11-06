defmodule ConciergeSite.AccountView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.User
  alias Ecto.Changeset
  alias Plug.Conn

  defdelegate email(user), to: User
  defdelegate phone_number(user), to: User

  def phone_number?(user) do
    phone_number = User.phone_number(user)
    is_binary(phone_number) and phone_number != ""
  end

  def fetch_field!(changeset, field) do
    {_, value} = Changeset.fetch_field(changeset, field)
    value
  end

  def sms_frozen?(%{data: user}), do: User.inside_opt_out_freeze_window?(user)

  @spec format_phone_number(String.t()) :: String.t()
  def format_phone_number(
        <<area_code::binary-size(3), exchange::binary-size(3), extension::binary-size(4)>>
      ),
      do: "#{area_code}-#{exchange}-#{extension}"

  def format_phone_number(number), do: number

  @spec update_profile_url(Conn.t()) :: String.t()
  def update_profile_url(conn),
    do: ConciergeSite.Router.Helpers.auth_url(conn, :request, :update_profile)

  @spec edit_password_url(Conn.t()) :: String.t()
  def edit_password_url(conn),
    do: ConciergeSite.Router.Helpers.auth_url(conn, :request, :edit_password)
end
