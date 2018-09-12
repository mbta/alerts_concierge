from locust import TaskSet, task


class SettingsPage(TaskSet):
    """Load the account settings page"""

    @task
    def view_settings(self):
        self.client.get("/account/edit")
