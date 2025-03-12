# alerts_concierge Data Model

## User-Driven

In alerts_concierge, *trips* (referred to in the UI as “subscriptions”) represent an entire commute, potentially including transfers and a return journey.

A trip is composed of multiple *subscriptions*, representing an individual leg of a commute; subscriptions have a single time range, a single route, a single direction, and a single pair of stops where they start and end (except for bus, where there are no endpoints).
Transfers create different subscriptions on the same trip (with a higher `rank`), multiple bus route selections and the Green Line trunk create different subscriptions on the same trip (one per `route`), and return trips create different subscriptions on the same trip (with `return_trip` `true` and the opposite `direction_id`).

For commuter rail and ferry, to support riders who plan around individual scheduled trips, the UI presents a list of trips during the selected time range, appearing to allow the individual scheduled trips themselves to be included or excluded from the subscription.
However, the subscription only tracks this information in `travel_start_time`/`travel_end_time`, which is set in the interface to between the first and the last selected trip, and indeed the interface does not allow the selection of non-contiguous sets of trips.
Storing selected trips by ID would lead to selections losing meaning at new ratings if trip IDs change; this approach allows an equivalent trip at the same time to remain selected if its ID changes in the new rating.

A trip can instead represent a non-time-windowed interest in accessibility information (`trip_type` of `accessibility` rather than `commute`, and subscription `type`s of `accessibility` rather than `subway`/`bus`/`cr`/`ferry`).

## Data-Driven

The entry point for handling new alerts is `AlertParser.process_alerts/1`, which will

1. Fetch alerts directly in enhanced JSON format to get information like `last_push_notification_timestamp` that’s absent from the API, but also via the API to get multi-route trips handled automatically
2. Run its rules engine to determine which subscriptions should receive notifications for which alerts
3. Create `Notification`s linked via `NotificationSubscription`s to those subscriptions
4. Enqueue those notifications to be sent out

## Notes

- The `versions` table is write-only as of 2018.
- The `informed_entities` table appears to not actually be used.
- Static GTFS data is cached locally in `apps/alert_processor/priv/service_info_cache` and will only be updated if the local service runs for more than a day.
