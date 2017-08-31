defmodule ConciergeSite.VacationView do
  use ConciergeSite.Web, :view
  alias Calendar.Strftime

  @doc """
  Stringify User changeset vacation_start or vacation_end DateTime into
  MM/DD/YYYY format
  """
  def format_vacation_time(nil), do: nil
  def format_vacation_time(time) when is_binary(time), do: time
  def format_vacation_time(%DateTime{} = time) do
    case Strftime.strftime(time, "%m/%d/%Y") do
      {:ok, datetime_string} -> datetime_string
      {:error, _} -> nil
    end
  end
end
