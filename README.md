# Alerts Concierge

a.k.a. **[T-Alerts](https://alerts.mbta.com/)**. Enables MBTA riders to
subscribe to notifications for service disruptions.

## Setup

### Requirements

- MBTA API key (get one [here](https://api-dev.mbtace.com))
  - **Note:** This key must have its version set to `2019-02-12`
  - You may need to request an increased rate limit if you get errors during
    the first app startup; 2000 requests per minute should be enough
- PostgreSQL 13 (using Homebrew: `brew install postgresql@13`)
  - You will need Postgres client tools in your PATH; if using Homebrew and you
    get an error about missing tools, use `brew link postgresql@13`
- [Google Chrome](https://www.google.com/chrome/)
- Chromedriver (using Homebrew: `brew cask install chromedriver`)
- [`asdf`](https://asdf-vm.com/) with plugins: `elixir`, `erlang`, `nodejs`
- [`direnv`](https://direnv.net/) _(optional, for auto-loading env vars)_

### Instructions

1. `asdf install`
2. `mix deps.get`
3. `npm install --prefix apps/concierge_site/assets`
4. `cat .envrc.example | sed -e "s/__username__/$(logname)/g" > .envrc`
5. In `.envrc`: Fill in `API_KEY=` with the API key you obtained above
6. `direnv allow`
7. `mix ecto.setup`
8. `MIX_ENV=test mix ecto.setup`

The above assumes you have a PostgreSQL user with the same name as your OS user
(`logname`), which should be the default with a Homebrew install. Otherwise, you
may need to adjust the username in `.envrc`.

If not using `direnv`, you can instead `source .envrc` to perform a one-time
export of the environment variables into your current shell session.

### Running tests

- `mix test`

### Running the application

- `mix phx.server`
- Visit <http://localhost:4005/>

## Deployment

We run the app on AWS: see [`docs/aws.md`](docs/aws.md) for deployment guides.
