# --- Set up Elixir build ---
FROM hexpm/elixir:1.13.3-erlang-24.2.2-debian-bullseye-20210902-slim as elixir-builder

ENV LANG=C.UTF-8 MIX_ENV=prod

RUN apt-get update --allow-releaseinfo-change
RUN apt-get install --no-install-recommends --yes \
  build-essential ca-certificates git
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /root
ADD . .
RUN mix deps.get --only prod


# --- Build frontend assets ---
FROM node:14.17.6-bullseye-slim as asset-builder

RUN apt-get update --allow-releaseinfo-change
RUN apt-get install --no-install-recommends --yes ca-certificates git

# Allow asset build to reference files provided by Elixir dependencies
WORKDIR /root
COPY --from=elixir-builder /root/deps ./deps

WORKDIR /root/apps/concierge_site/assets
ADD apps/concierge_site/assets .
RUN npm install
RUN npm run deploy


# --- Build Elixir release ---
FROM elixir-builder as app-builder

WORKDIR /root/apps/concierge_site/priv/static
COPY --from=asset-builder /root/apps/concierge_site/priv/static .

WORKDIR /root
RUN mix compile
RUN mix phx.digest
RUN mix release


# --- Set up runtime container ---
FROM debian:bullseye-slim

ENV LANG=C.UTF-8 MIX_ENV=prod REPLACE_OS_VARS=true

RUN apt-get update --allow-releaseinfo-change \
  && apt-get install --no-install-recommends --yes dumb-init \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root
COPY --from=app-builder /root/_build/prod/rel/alerts_concierge .

EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bin/alerts_concierge", "start"]
