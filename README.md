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

## Using the application

### Staging

The staging server can be found at
[ec2-34-205-43-57.compute-1.amazonaws.com](http://ec2-34-205-43-57.compute-1.amazonaws.com).
