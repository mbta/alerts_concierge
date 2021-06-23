# Deploying

The app lives on AWS in three environments, `alerts-concierge-prod`,
`alerts-concierge-dev`, and `alerts-concierge-dev-green`. The app runs as an
Elixir release in a Docker container. The Docker images are hosted on AWS ECR,
and the containers are run on Fargate.

Deploying to the environments is done via GitHub Actions:

* Commits on the main branch are auto-deployed to `dev` if they pass CI.

* Manual deploys to all environments are done via the [deploy workflow][deploy]:
  Click "Run workflow", select a branch, and enter the environment to deploy to.
  Only the main branch can be deployed to `prod` and `dev`; use `dev-green` to
  test unmerged branches.

[deploy]: https://github.com/mbta/alerts_concierge/actions/workflows/deploy.yml

## Rolling back a deploy

Note currently you can only select a _branch_ in the deploy workflow, not a tag
or an arbitrary commit — this is a limitation of GitHub Actions. If you need to
roll back a deploy, you will have to temporarily create and push a branch that
is at the commit you want to roll back to, i.e.:

1. `git checkout <SHA>`
2. `git checkout -b temp-deploy`
3. `git push -u`
4. Select `temp-deploy` in the workflow

You can find the required SHA using the [deploy log][log] for the environment
you are rolling back.

[log]: https://github.com/mbta/alerts_concierge/deployments/activity_log

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
