from locust import TaskSequence, seq_task
from page import Page


class CreateCommuterRailSubscription(TaskSequence):
    """Sequence to create a commuter rail subscription"""

    @seq_task(1)
    def visit_new_subscription_page(self):
        response = self.client.get("/trip/new")
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(2)
    def select_route(self):
        response = self.client.post(
            "/trip/leg",
            json={
                "mode_toggle": "cr",
                "trip": {
                    "alternate_routes": "%7B%7D",
                    "from_new_trip": "true",
                    "round_trip": "true",
                    "route": "CR-Worcester~~Framingham/Worcester Line~~cr"
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(3)
    def select_origin_destination(self):
        response = self.client.post(
            "/trip/leg",
            json={
                "mode_toggle": "subway",
                "trip": {
                    "alternate_routes": "%7B%7D",
                    "destination": "place-sstat",
                    "new_leg": "false",
                    "origin": "place-WML-0442",
                    "round_trip": "true",
                    "route": "Red~~Red Line~~subway",
                    "saved_leg": "CR-Worcester",
                    "saved_mode": "cr"
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(4)
    def select_times(self):
        self.client.post(
            "/trip",
            json={
                "trip": {
                    "alternate_routes": "%7B%7D",
                    "bike_storage": "false",
                    "destinations": ["place-sstat"],
                    "elevator": "false",
                    "end_time": {"am_pm": "AM", "hour": "9", "minute": "0"},
                    "escalator": "false",
                    "legs": ["CR-Worcester"],
                    "modes": ["cr"],
                    "origins": ["place-WML-0442"],
                    "parking_area": "true",
                    "relevant_days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
                    "return_end_time": {"am_pm": "PM", "hour": "6", "minute": "0"},
                    "return_start_time": {"am_pm": "PM", "hour": "5", "minute": "0"},
                    "round_trip": "true",
                    "schedule_return": {"CR-Worcester": ["17:40:00"]},
                    "schedule_start": {"CR-Worcester": ["08:50:00"]},
                    "start_time": {"am_pm": "AM", "hour": "8", "minute": "0"}
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )

    @seq_task(5)
    def visit_trips_index_page(self):
        self.client.get("/trips")
