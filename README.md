# Alerts Concierge

[![Build status](https://semaphoreci.com/api/v1/projects/de013d4d-9f29-4afd-83d4-85f13e0699e6/1892610/badge.svg)](https://semaphoreci.com/mbta/alerts_concierge)
[![Code coverage](https://codecov.io/gh/mbta/alerts_concierge/branch/master/graph/badge.svg?token=yvAzhPtUcf)](https://codecov.io/gh/mbta/alerts_concierge)

a.k.a. **[T-Alerts](https://alerts.mbta.com/)**. Enables MBTA riders to
subscribe to notifications for service disruptions.

## Setup

### Requirements

- MBTA API key (get one [here](https://dev.api.mbtace.com))
  - **Note:** This key must have its version set to `2019-04-05`
- PostgreSQL 10 (using Homebrew: `brew install postgresql@10`)
- Chromedriver (using Homebrew: `brew cask install chromedriver`)
- Erlang, Elixir, and Node.js versions specified in `.tool_versions`
  - Use [`asdf`](https://github.com/asdf-vm/asdf) to install automatically
    - Note [these extra install steps][nodejs-reqs] for NodeJS plugin
- Yarn (`npm install -g yarn`; may require `asdf reshim` after)
- [direnv](https://github.com/direnv/direnv) _(optional, but convenient)_

[nodejs-reqs]: https://github.com/asdf-vm/asdf-nodejs#requirements

### Instructions

- `mix deps.get`
- `sh -c "cd apps/concierge_site/assets ; yarn install"`
- `cat .envrc.example | sed -e "s/__username__/$(logname)/g" > .envrc`
- In `.envrc`: Fill in `API_KEY=` with the API key you obtained above
- `direnv allow`
- `mix ecto.setup`
- `MIX_ENV=test mix ecto.setup`

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

## Deployment

We run the app on AWS: see [`docs/aws.md`](docs/aws.md) for deployment guides.
