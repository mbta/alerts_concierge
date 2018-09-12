from locust import TaskSequence, seq_task
from page import Page


class CreateRedLineSubscription(TaskSequence):
    """Sequence to create a red line subscription"""

    @seq_task(1)
    def visit_new_subscription_page(self):
        response = self.client.get("/trip/new")
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(2)
    def select_route(self):
        response = self.client.post(
            "/trip/leg",
            json={
                "mode_toggle": "subway",
                "trip": {
                    "alternate_routes": "%7B%7D",
                    "from_new_trip": "true",
                    "round_trip": "true",
                    "route": "Red~~Red Line~~subway"
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
                    "destination": "place-dwnxg",
                    "new_leg": "false",
                    "origin": "place-harsq",
                    "round_trip": "true",
                    "route": "Red~~Red Line~~subway",
                    "saved_leg": "Red",
                    "saved_mode": "subway"
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
                    "start_time": {"minute": "0", "hour": "8", "am_pm": "AM"},
                    "round_trip": "true",
                    "return_start_time": {"minute": "0", "hour": "5", "am_pm": "PM"},
                    "return_end_time": {"minute": "0", "hour": "6", "am_pm": "PM"},
                    "relevant_days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
                    "parking_area": "false",
                    "origins": ["place-harsq"],
                    "modes": ["subway"],
                    "legs": ["Red"],
                    "escalator": "false",
                    "end_time": {"minute": "0", "hour": "9", "am_pm": "AM"},
                    "elevator": "true",
                    "destinations": ["place-dwnxg"],
                    "bike_storage": "false",
                    "alternate_routes": "%7B%7D"
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )

    @seq_task(5)
    def visit_trips_index_page(self):
        self.client.get("/trips")
