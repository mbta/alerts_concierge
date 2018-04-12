# Alerts Concierge

Subscription and dissemination system which allows MBTA customers to easily
subscribe to and receive relevant service alerts for desired
itineraries/services, while ensuring MBTA’s costs for providing this
functionality remain low and that MBTA can manage and improve the system.

## Setup

### Requirements

* PostgreSQL ~10.0
* Elixir 1.5.2 (you can use [asdf](https://github.com/asdf-vm/asdf) with
  [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) to manage Elixir
  versions)
* Node.js 8.7.0 (you can use [asdf](https://github.com/asdf-vm/asdf) with
  [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) or
  [nvm](https://github.com/creationix/nvm) to manage Node.js versions)
* Yarn ~1.3.2
* MBTA API key (get one [here](https://dev.api.mbtace.com))

### Instructions

* `git clone git@github.com:mbta/alerts_concierge.git`
* `cd alerts_concierge`
* `mix deps.get`
* `sh -c "cd apps/concierge_site/assets ; yarn install"`
* `cat .env.example | sed -e "s/__username__/$(logname)/g" > .env`
* ``env `cat .env` mix ecto.setup``
* `echo 'API_KEY=<YOUR_MBTA_API_KEY>' >> .env`

#### Notes

The steps above assume that you have PostgreSQL set up with a user named
`logname`, which should be the default if you used Homebrew to install it.
You may need to adjust the username in `.env` depending on your PostgreSQL
configuration.

### Running tests

#### Running all tests and code coverage

* ``env  `cat .env` MIX_ENV=test mix test.all``

#### Running only Elixir tests

* ``env  `cat .env` mix test``

### Running the application

* ``env  `cat .env` mix phx.server``
* Visit [localhost:4005](http://localhost:4005/)

### More information

For more information about setup and use of the application, see the
[Wiki](https://github.com/mbta/alerts_concierge/wiki).

## AWS

The Alerts Concierge application lives on AWS in three environments, `alerts-concierge-prod`, `alerts-concierge-dev`, and `alerts-concierge-dev-green`. The app runs as a release in a docker container. The docker images are hosted on AWS ECR, and the containers are run on Fargate.

### Deployment

Deployment to the environments is done via SemaphoreCI.

Deploying to `alerts-concierge-prod` is done manually, by choosing a branch (usually `master`), choosing the desired build, clicking "Deploy manually", choosing "Production", and pressing the "Deploy" button. Before deploying to production, note what build of `master` is currently deployed in case you need to rollback (i.e.: re-deploy that earlier build using the steps above.)

Every merge to master automatically deploys the newest version to `alerts-concierge-dev`.

`alerts-concierge-dev-green` is used to test branches in a production-esque environment. It can be deployed to in a similar way as to Production, but choose "Dev Green" instead. Ask in the slack channel if anyone is using that environment before doing so.

### Changing ENV variables

Here's how to change them on AWS:

1. Go to Elastic Container Service AWS page (https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters)
1. Click "Task Definitions" in the sidebar
1. Check the box next to the environment that you want to make the change to (e.g. alerts-concierge-dev-green).
1. This should enable the "Create new revision" button along the top. Click it. This clones the most recent settings so you can make the changes you want.
1. In the "Container Definitions" section 2/3 of the way down, click the link in the table under Container Name (e.g. alerts-concierge-dev-green). A panel should slide in from the side.
1. In this panel, there's an "Env Variables" section. You can create, delete, or update environment variables there.
1. Click the "Update" button on the bottom. The panel slides away.
1. Click the "Create" button on the bottom. There should be a green "Created new revision of Task Defintion foo:# successfully" at the top.

At this point, the newest task definition has the desired environment variables. However, the alerts-concierge app will still be running the old task definition. To make the app restart, picking up the new changes, it needs to be re-deployed from semaphore.
