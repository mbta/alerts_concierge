from locust import TaskSequence, seq_task
from page import Page


class CreateBusSubscription(TaskSequence):
    """Sequence to create a bus subscription"""

    @seq_task(1)
    def visit_new_subscription_page(self):
        response = self.client.get("/trip/new")
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(2)
    def select_route(self):
        response = self.client.post(
            "/trip/leg",
            json={
                "mode_toggle": "bus",
                "trip": {
                    "alternate_routes": "%7B%221%20-%201%22:%5B%22701%20-%201~~Route%20CT1~~bus%22%5D%7D",
                    "from_new_trip": "true",
                    "round_trip": "true",
                    "route": "1 - 1~~Route 1~~bus"
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )
        self.csrf_token = Page.get_csrf_token(response)

    @seq_task(3)
    def select_direction(self):
        response = self.client.post(
            "/trip/leg",
            json={
                "mode_toggle": "subway",
                "trip": {
                    "alternate_routes": "%7B%221%20-%200%22:%5B%22701%20-%200~~Route%20CT1~~bus%22%5D%7D",
                    "destination": None,
                    "direction": "0",
                    "new_leg": "false",
                    "origin": None,
                    "round_trip": "true",
                    "route": "Red~~Red Line~~subway",
                    "saved_leg": "1 - 0",
                    "saved_mode": "bus"
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
                    "alternate_routes": "%7B%221%20-%200%22:[%22701%20-%200~~Route%20CT1~~bus%22]%7D",
                    "bike_storage": "false",
                    "destinations": [None],
                    "elevator": "false",
                    "end_time": {"am_pm": "AM", "hour": "9", "minute": "0"},
                    "escalator": "false",
                    "legs": ["1 - 0"],
                    "modes": ["bus"],
                    "origins": [None],
                    "parking_area": "false",
                    "relevant_days": ["saturday", "sunday"],
                    "return_end_time": {"am_pm": "PM", "hour": "6", "minute": "0"},
                    "return_start_time": {"am_pm": "PM", "hour": "5", "minute": "0"},
                    "round_trip": "true",
                    "start_time": {"am_pm": "AM", "hour": "8", "minute": "0"}
                },
                "_utf8": "✓",
                "_csrf_token": self.csrf_token
            }
        )

    @seq_task(5)
    def visit_trips_index_page(self):
        self.client.get("/trips")
