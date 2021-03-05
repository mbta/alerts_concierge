# Deploying

The app lives on AWS in three environments, `alerts-concierge-prod`,
`alerts-concierge-dev`, and `alerts-concierge-dev-green`. The app runs as an
Elixir release in a Docker container. The Docker images are hosted on AWS ECR,
and the containers are run on Fargate.

Deploying to the environments is done via [Semaphore]:

* `prod` is deployed manually, by choosing a desired build (normally the latest
  build of `master`), clicking "Deploy manually", choosing "Production", and
  pressing the "Deploy" button. Before deploying to production, note which build
  is currently deployed in case you need to roll back (i.e. re-deploy that build
  using these same steps).

* Any new commits on `master` are automatically deployed to `dev`.

* `dev-green` is used to test unmerged branches. It can be deployed to in a
  similar way as to Production, but choose "Dev Green" instead. Ask in the Slack
  channel if anyone is using that environment before doing so.

[Semaphore]: https://semaphoreci.com/mbta/alerts_concierge

## Environment variables

Here's how to change them on AWS:

1. Go to the [ECS dashboard]

1. Click "Task Definitions" in the sidebar

1. Check the box next to the environment that you want to make the change to

1. This should enable the "Create new revision" button along the top. Click it.
   This clones the most recent settings so you can make the changes you want.

1. In the "Container Definitions" section 2/3 of the way down, click the link in
   the table under Container Name (e.g. alerts-concierge-dev-green). A panel
   should slide in from the side.

1. In this panel, there's an "Env Variables" section. You can create, delete, or
   update environment variables there.

1. Click the "Update" button on the bottom. The panel slides away.

1. Click the "Create" button on the bottom. There should be a green "Created new
   revision of Task Defintion foo:# successfully" at the top.

At this point, the newest task definition has the desired environment variables.
However, the alerts-concierge app will still be running the old task definition.
To make the app restart, picking up the new changes, it needs to be re-deployed
from Semaphore.

[ECS dashboard]: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters
