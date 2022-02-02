defmodule ConciergeSite.TimeHelper do
  @moduledoc """
  Time functions for subscription views
  """

  import Phoenix.HTML.Form, only: [select: 4, time_select: 3]
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  alias Calendar.Strftime

  @doc """
  Takes a time struct and returns HH:MM AM/PM
  """
  @spec format_time(DateTime.t() | nil, String.t(), boolean) :: String.t()
  def format_time(time, format \\ "%l:%M %p", strip_leading_zero? \\ false)
  def format_time(nil, _, _), do: ""

  def format_time(time, format, strip_leading_zero?) do
    formatted_time =
      time
      |> time_to_string()
      |> format_time_string(format)

    if strip_leading_zero?, do: Regex.replace(~r/^0?/, formatted_time, ""), else: formatted_time
  end

  @doc """
  Takes a time string in format HH:MM:SS and returns HH:MM AM/PM
  """
  def format_time_string(time_string, format \\ "%I:%M %p") do
    time_string
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
    |> Time.from_erl!()
    |> Strftime.strftime!(format)
  end

  @doc """
  Converts a Time.t to a string with the H:M:S format
  """
  @spec time_to_string(Time.t() | nil) :: String.t() | nil
  def time_to_string(nil), do: nil
  def time_to_string(time), do: Strftime.strftime!(time, "%H:%M:%S")

  @spec trip_time_select(Phoenix.HTML.Form.t(), atom, DateTime.t() | Time.t()) ::
          Phoenix.HTML.Safe.t()
  def trip_time_select(form, field, time) do
    content_tag :div, class: "form__time" do
      time_select(form, field, builder: &time_select_builder(&1, field, time))
    end
  end

  defp time_select_builder(builder, field, time) do
    content_tag :div do
      [
        content_tag(:label, "Hour", for: "form__time_hour", class: "sr-only"),
        builder.(
          :hour,
          required: true,
          options: zero_padded_numbers().(1..12),
          value: format_time(time, "%I", true),
          id: "trip_#{field}_hour",
          data: [type: "time"]
        ),
        content_tag(:span, ":"),
        content_tag(:label, "Minute", for: "form__time_minute", class: "sr-only"),
        builder.(
          :minute,
          required: true,
          value: format_time(time, "%M", true),
          id: "trip_#{field}_minute",
          data: [type: "time"]
        ),
        " ",
        content_tag(:label, "AM or PM", for: "form__time_am_pm", class: "sr-only"),
        select(
          :trip,
          :am_pm,
          [AM: "AM", PM: "PM"],
          required: true,
          value: format_time(time, "%p"),
          id: "trip_#{field}_am_pm",
          name: "trip[#{field}][am_pm]",
          data: [type: "time"]
        )
      ]
    end
  end

  defp zero_padded_numbers do
    &Enum.map(&1, fn i ->
      pre = if i < 10, do: "0"
      {"#{pre}#{i}", i}
    end)
  end
end
