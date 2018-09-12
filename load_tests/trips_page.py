from locust import TaskSet, task


class TripsPage(TaskSet):
    """Load the trips index page"""

    @task
    def view_trips(self):
        self.client.get("/trips")
