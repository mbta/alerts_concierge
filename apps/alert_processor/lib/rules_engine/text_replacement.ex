defmodule AlertProcessor.TextReplacement do
  alias AlertProcessor.{Model, ServiceInfoCache}
  alias Model.Alert
  alias Calendar.DateTime, as: DT
  alias Calendar.Strftime

  def replace_text(alert, subscriptions) do
    if Alert.commuter_rail_alert?(alert) do
      {stop_schedules, trip_schedules} = build_schedule_mapping(alert.informed_entities)

      match_targets = %{
        description: parse_target(alert.description),
        header: parse_target(alert.header)
      }

      trip_mapping = for {key, targets} <- match_targets, into: %{} do
        trips =
          targets
          |> Enum.flat_map(fn({index, {target, _text}}) ->
            trip = Map.get(stop_schedules, target)
            Enum.reduce(subscriptions, %{}, fn(sub, acc) ->
              case trip_schedules[{sub.origin, trip}] do
                %Time{} = time -> Map.put(acc, index, {sub.origin, time})
                _ -> acc
              end
            end)
          end)
          |> Enum.map(fn({k, replacement}) ->
            {original, text} = match_targets[key][k]
            if original != replacement do
              {original, replacement, text}
            end
          end)
        {key, trips}
      end

      replace_schedule(trip_mapping, alert)
    else
      %{
        header: alert.header,
        description: alert.description
      }
    end
  end

  defp replace_schedule(replacement_data, alert) do
    for {key, replacement_pairs} <- replacement_data, into: %{} do
      if replacement_pairs == [] do
        {key, Map.get(alert, key)}
      else
        text =
          replacement_pairs
          |> Enum.map(fn({_original, replacement, text}) ->
            new_text = serialize(replacement)
            substitute(text, new_text)
          end)
        {key, text}
      end
    end
  end

  defp serialize({stop, time}) do
    time_string = Strftime.strftime!(time, "%H:%M %p")
    "(#{time_string} from #{stop})"
  end

  defp substitute(text, new) do
    String.replace(text, schedule_regex(), new)
  end

  defp schedule_regex do
    ~r/(?<train_number>\d{2,3})\s*\((?<time>\d{1,2}\:\d{2}\s*[a|p|A|P)][m|M])\sfrom\s(?<station>[\w\s]+)\)/
  end

  defp parse_target(text) when is_binary(text) do
    schedule_regex()
    |> Regex.scan(text)
    |> Enum.with_index() # TODO: Handle no match
    |> Enum.reduce(%{}, fn({[_, _train, time, station], index}, acc) ->
      Map.put(acc, index, {{station, parse_time(time)}, text})
    end)
  end
  defp parse_target(_), do: %{}

  defp parse_time(time_with_ampm) do
    time_regex = ~r/\:|\s*[aApP][mM]/

    [hour, minute] =
      time_with_ampm
      |> String.split(time_regex, trim: true)
      |> Enum.map(&String.to_integer/1)

    if String.ends_with?(time_with_ampm, ["pm", "PM"]) do
      Time.from_erl!({hour + 12, minute, 0})
    else
      Time.from_erl!({hour + 12, minute, 0})
    end
  end

  defp build_schedule_mapping(informed_entities) do
    informed_entities
    |> Enum.reject(& is_nil(&1.schedule))
    |> Enum.reduce({%{}, %{}}, fn(informed_entity, {stop_time_trips, trip_schedules}) ->
      Enum.reduce(informed_entity.schedule, {stop_time_trips, trip_schedules}, fn(schedule, {stop_time_trips, trip_schedules}) ->
        case ServiceInfoCache.get_stop(schedule.stop_id) do
          {:ok, {stop_name, _}} ->
            departure_time = extract_time(schedule.departure_time)
            stop_time_trips = Map.put(stop_time_trips, {stop_name, departure_time}, schedule.trip_id)
            trip_schedules = Map.put(trip_schedules, {stop_name, schedule.trip_id}, departure_time)
            {stop_time_trips, trip_schedules}
          _ -> {stop_time_trips, trip_schedules}
        end
      end)
    end)
  end

  defp extract_time(datetime) do
    {:ok, dt} = DT.Parse.rfc3339(datetime, "America/New_York")
    DateTime.to_time(dt)
  end
end
