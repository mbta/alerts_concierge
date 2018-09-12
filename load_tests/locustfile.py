from locust import HttpLocust, TaskSet, TaskSequence, task, seq_task
from create_bus_subscription import CreateBusSubscription
from create_commuter_rail_subscription import CreateCommuterRailSubscription
from create_red_line_subscription import CreateRedLineSubscription
from page import Page
from settings_page import SettingsPage
from trips_page import TripsPage
from user import User


class UserBehavior(TaskSet):
    tasks = {
        TripsPage: 1,
        SettingsPage: 1,
        CreateRedLineSubscription: 3,
        CreateBusSubscription: 3,
        CreateCommuterRailSubscription: 3
    }

    def on_start(self):
        """ on_start is called when Locust starts before any task is scheduled """
        self.signup()

    def signup(self):
        response = self.client.get("/account/new")
        csrf_token = Page.get_csrf_token(response)

        self.email = User.random_email()
        self.password = User.random_password()

        self.client.post(
            "/account",
            json={
                "user": {
                    "email": self.email,
                    "password": self.password
                },
                "_utf8": "✓",
                "_csrf_token": csrf_token
            }
        )


class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    min_wait = 5000  # 5 seconds
    max_wait = 15000  # 15 seconds
