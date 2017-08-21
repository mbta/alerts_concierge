defmodule AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  alias AlertProcessor.{Model.InformedEntity, Model.Subscription, Helpers.DateTimeHelper, TimeFrameComparison}

  defstruct [:active_period, :effect_name, :id, :header, :informed_entities,
             :severity, :last_push_notification, :service_effect, :description,
             :timeframe, :recurrence]

  @type informed_entity :: [
    %{
      optional(:direction_id) => integer,
      optional(:facility_type) => InformedEntity.facility_type,
      optional(:route) => String.t,
      optional(:route_type) => integer,
      optional(:stop) => String.t,
      optional(:trip) => String.t
    }
  ]

  @type t :: %__MODULE__{
    active_period: [%{start: DateTime.t, end: DateTime.t | nil}],
    effect_name: String.t,
    header: String.t,
    id: String.t,
    informed_entities: [informed_entity],
    severity: atom,
    last_push_notification: DateTime.t,
    service_effect: String.t,
    description: String.t,
    timeframe: String.t,
    recurrence: String.t,
  }

  @route_types %{
    0 => "Subway",
    1 => "Subway",
    2 => "Commuter Rail",
    3 => "Bus",
    4 => "Ferry"
  }

  @severity_map %{
    "Subway" => %{
      "Delay" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Extra Service" => %{
        moderate: 3,
        severe: 3
      },
      "Schedule Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Service Change" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Shuttle" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Station Closure" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Station Issue" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Suspension" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      }
    },
    "Commuter Rail" => %{
      "Cancellation" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Delay" => %{
        moderate: 3,
        severe: 3
      },
      "Extra Service" => %{
        severe: 3
      },
      "Schedule Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Service Change" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Shuttle" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Station Closure" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Suspension" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Track Change" => %{
        minor: 3
      }
    },
    "Bus" => %{
      "Delay" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Detour" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Extra Service" => %{
        severe: 3
      },
      "Schedule Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Service Change" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Snow Route" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Stop Closure" => %{
        moderate: 3,
        severe: 3
      },
      "Stop Move" => %{
        severe: 3
      },
      "Suspension" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      }
    },
    "Ferry" => %{
      "Cancellation" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Delay" => %{
        moderate: 3,
        severe: 3
      },
      "Dock Closure" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Dock Issue" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Extra Service" => %{
        moderate: 3,
        severe: 3
      },
      "Schedule Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Service Change" => %{
        minor: 1,
        moderate: 2,
        severe: 3
      },
      "Shuttle" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Suspension" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
    },
    "Systemwide" => %{
      "Delay" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Extra Service" => %{
        moderate: 3,
        severe: 3
      },
      "Policy Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Service Change" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Suspension" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      },
      "Amber Alert" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      }
    },
    "Facility" => %{
      "Access Issue" => %{
        minor: 3,
        moderate: 3,
        severe: 3
      }
    }
  }

  @doc """
  return the numeric value for severity for a given alert. the higher the number
  the more severe.
  """
  @spec severity_value(__MODULE__.t) :: integer | nil
  def severity_value(%__MODULE__{severity: severity, effect_name: effect_name, informed_entities: informed_entities}) do
      informed_entities
      |> Enum.map(fn(informed_entity) ->
        mode =
          case informed_entity do
            %{route_type: rt, route: nil} when not is_nil(rt) -> "Systemwide"
            %{route_type: rt, route: r} when not is_nil(rt) and not is_nil(r) -> route_string(rt)
            %{stop: s} when not is_nil(s) -> "Facility"
          end
        priority_value(mode, effect_name, severity)
      end)
      |> Enum.max
  end

  @doc """
  parse alert active periods and return as timeframe map for comparison
  with subscriptions
  """
  @spec timeframe_maps(__MODULE__.t) :: [TimeFrameComparison.timeframe_map]
  def timeframe_maps(%__MODULE__{active_period: active_periods}) do
    for active_period <- active_periods do
      timeframe_map(active_period)
    end
  end

  @spec timeframe_map(%{start: DateTime.t, end: DateTime.t | nil}) :: boolean | TimeFrameComparison.timeframe_map
  defp timeframe_map(%{start: nil, end: _}), do: false
  defp timeframe_map(%{start: _, end: nil}), do: true
  defp timeframe_map(%{start: period_start, end: period_end}) do
    {start_date, start_time} = DateTimeHelper.datetime_to_date_and_time(period_start)
    {end_date, end_time} = DateTimeHelper.datetime_to_date_and_time(period_end)

    if Date.compare(start_date, end_date) == :eq do
      %{
        start_date
        |> Date.day_of_week
        |> Subscription.relevant_day_of_week_type =>
        %{
          start: DateTimeHelper.seconds_of_day(start_time),
          end: DateTimeHelper.seconds_of_day(end_time)
        }
      }
    else
      period_start
      |> DateTimeHelper.date_range(period_end)
      |> Enum.reduce(%{}, fn(current_date, acc) ->
        case current_date do
          ^start_date ->
            day_of_week_atom = Subscription.relevant_day_of_week_type(Date.day_of_week(start_date))

            Map.put(acc, day_of_week_atom, %{start: DateTimeHelper.seconds_of_day(start_time), end: 86_399})
          ^end_date ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(Date.day_of_week(end_date))

            Map.put_new(acc, relevant_day_of_week_atom, %{start: 0, end: DateTimeHelper.seconds_of_day(end_time)})
          date ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(Date.day_of_week(date))

            Map.put(acc, relevant_day_of_week_atom, %{start: 0, end: 86_399})
        end
      end)
    end
  end

  @spec route_string(integer) :: String.t
  defp route_string(route_type) do
    @route_types[route_type]
  end

  @spec priority_value(String.t, String.t, atom) :: integer
  defp priority_value(route_type, effect_name, severity) do
    @severity_map[route_type][effect_name][severity] || 0
  end
end
