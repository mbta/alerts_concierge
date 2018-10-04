defmodule AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  alias AlertProcessor.{
    Model.InformedEntity,
    Model.Subscription,
    Helpers.DateTimeHelper,
    TimeFrameComparison
  }

  defstruct [
    :active_period,
    :effect_name,
    :id,
    :header,
    :informed_entities,
    :severity,
    :last_push_notification,
    :service_effect,
    :description,
    :url,
    :timeframe,
    :recurrence,
    :duration_certainty,
    :created_at,
    :closed_timestamp,
    :reminder_times
  ]

  @type informed_entity :: [
          %{
            optional(:direction_id) => integer,
            optional(:facility_type) => InformedEntity.facility_type(),
            optional(:route) => String.t(),
            optional(:route_type) => integer,
            optional(:stop) => String.t(),
            optional(:trip) => String.t()
          }
        ]

  @type t :: %__MODULE__{
          active_period: [%{start: DateTime.t(), end: DateTime.t() | nil}],
          effect_name: String.t(),
          header: String.t(),
          id: String.t(),
          informed_entities: [informed_entity],
          severity: atom,
          last_push_notification: DateTime.t(),
          service_effect: String.t(),
          description: String.t(),
          url: String.t() | nil,
          timeframe: String.t(),
          recurrence: String.t(),
          duration_certainty: {:estimated, pos_integer} | :known,
          created_at: DateTime.t(),
          closed_timestamp: DateTime.t() | nil,
          reminder_times: [DateTime.t()] | nil
        }

  @doc """
  parse alert active periods and return as timeframe map for comparison
  with subscriptions
  """
  @spec timeframe_maps(__MODULE__.t()) :: [TimeFrameComparison.timeframe_map()]
  def timeframe_maps(%__MODULE__{active_period: active_periods}) do
    for active_period <- active_periods do
      timeframe_map(active_period)
    end
  end

  @spec timeframe_map(%{start: DateTime.t(), end: DateTime.t() | nil}) ::
          boolean | TimeFrameComparison.timeframe_map()
  defp timeframe_map(%{start: nil, end: _}), do: false
  defp timeframe_map(%{start: _, end: nil}), do: true

  defp timeframe_map(%{start: period_start, end: period_end}) do
    {start_date, start_time} = DateTimeHelper.datetime_to_date_and_time(period_start)
    {end_date, end_time} = DateTimeHelper.datetime_to_date_and_time(period_end)

    if Date.compare(start_date, end_date) == :eq do
      %{
        (start_date
         |> Date.day_of_week()
         |> Subscription.relevant_day_of_week_type()) => %{
          start: DateTimeHelper.seconds_of_day(start_time),
          end: DateTimeHelper.seconds_of_day(end_time)
        }
      }
    else
      period_start
      |> DateTimeHelper.date_range(period_end)
      |> Enum.reduce(%{}, fn current_date, acc ->
        case current_date do
          ^start_date ->
            day_of_week_atom =
              Subscription.relevant_day_of_week_type(Date.day_of_week(start_date))

            Map.put(acc, day_of_week_atom, %{
              start: DateTimeHelper.seconds_of_day(start_time),
              end: 86_399
            })

          ^end_date ->
            relevant_day_of_week_atom =
              Subscription.relevant_day_of_week_type(Date.day_of_week(end_date))

            Map.put_new(acc, relevant_day_of_week_atom, %{
              start: 0,
              end: DateTimeHelper.seconds_of_day(end_time)
            })

          date ->
            relevant_day_of_week_atom =
              Subscription.relevant_day_of_week_type(Date.day_of_week(date))

            Map.put(acc, relevant_day_of_week_atom, %{start: 0, end: 86_399})
        end
      end)
    end
  end

  defp timeframe_map(%{start: _}), do: true

  @spec commuter_rail_alert?(__MODULE__.t()) :: boolean()
  def commuter_rail_alert?(%__MODULE__{informed_entities: ies}) when is_list(ies) do
    Enum.any?(ies, &(&1.route_type == 2))
  end

  def commuter_rail_alert?(_), do: false

  @spec mode_alert?(__MODULE__.t()) :: boolean()
  def mode_alert?(%__MODULE__{informed_entities: ies}) when is_list(ies),
    do: Enum.any?(ies, &(InformedEntity.entity_type(&1) == :mode))

  def mode_alert?(_), do: false
end
