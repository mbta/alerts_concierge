# Alerts Concierge

[![Build Status](https://semaphoreci.com/api/v1/projects/de013d4d-9f29-4afd-83d4-85f13e0699e6/1892610/badge.svg)](https://semaphoreci.com/mbta/alerts_concierge)
[![codecov](https://codecov.io/gh/mbta/alerts_concierge/branch/master/graph/badge.svg?token=yvAzhPtUcf)](https://codecov.io/gh/mbta/alerts_concierge)

Subscription and dissemination system which allows MBTA customers to easily
subscribe to and receive relevant service alerts for desired
itineraries/services, while ensuring MBTA’s costs for providing this
functionality remain low and that MBTA can manage and improve the system.

## Setup

### Requirements

- MBTA API key (get one [here](https://dev.api.mbtace.com))
  - **Note:** This key must have its version set to `2019-04-05`
- PostgreSQL 10 (using Homebrew: `brew install postgresql@10`)
- Chromedriver (using Homebrew: `brew cask install chromedriver`)
- Erlang, Elixir, and Node.js versions specified in `.tool_versions`
  - Use [`asdf`](https://github.com/asdf-vm/asdf) to install automatically
    - Note [these extra install steps][nodejs-reqs] for NodeJS plugin
    - Use [this workaround][erlang-fix] to compile Erlang on Mac OS Catalina
- Yarn (`npm install -g yarn`; may require `asdf reshim` after)
- [direnv](https://github.com/direnv/direnv) _(optional, but convenient)_

[nodejs-reqs]: https://github.com/asdf-vm/asdf-nodejs#requirements
[erlang-fix]: https://github.com/kerl/kerl/issues/320#issuecomment-556565250

### Instructions

- `mix deps.get`
- `sh -c "cd apps/concierge_site/assets ; yarn install"`
- `cat .envrc.example | sed -e "s/__username__/$(logname)/g" > .envrc`
- In `.envrc`: Fill in `API_KEY=` with the API key you obtained above
- `direnv allow`
- `mix ecto.setup`
- `MIX_ENV=test mix ecto.setup`

#### Notes

The above assumes you have a PostgreSQL user with the same name as your OS user
(`logname`), which should be the default with a Homebrew install. Otherwise, you
may need to adjust the username in `.envrc`.

If not using `direnv`, you can instead `source .envrc` as it is a valid shell
script. However A) this will not persist beyond the current shell session, and
B) it will persist _through_ the session, even if you change directories.

### Running tests

- `mix test`

### Running the application

- `mix phx.server`
- Visit <http://localhost:4005/>

### More information

For more information about setup and use of the application, see the
[Wiki](https://github.com/mbta/alerts_concierge/wiki).

## Querying historical data

We occasionally get one-off questions about how T-Alerts behaved in the past, for example, whether a certain notification was sent out and when. In order to answer such questions we generally need to query the production database. The production database is not directly accessible, but we can be accessed by connecting through the [Bastion Host Gateway](https://github.com/mbta/wiki/blob/master/devops/bastion-host.md). Obviously the production database should only be interacted with _very carefully_.

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
