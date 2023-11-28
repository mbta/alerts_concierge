# --- Set up Elixir build ---
ARG ELIXIR_VERSION=1.14.5
ARG ERLANG_VERSION=26.1.2
ARG DEBIAN_NAME=bullseye
ARG DEBIAN_VERSION=${DEBIAN_NAME}-20230612
ARG NODE_VERSION=18.14.0

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-debian-${DEBIAN_VERSION}-slim as elixir-builder

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
FROM node:${NODE_VERSION}-${DEBIAN_NAME}-slim as asset-builder

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
FROM debian:${DEBIAN_NAME}-slim

ENV LANG=C.UTF-8 MIX_ENV=prod REPLACE_OS_VARS=true

RUN apt-get update --allow-releaseinfo-change \
  && apt-get install --no-install-recommends --yes dumb-init ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root
COPY --from=app-builder /root/_build/prod/rel/alerts_concierge .

# Ensure SSL support is enabled
RUN env SECRET_KEY_BASE= HOST_URL= DATABASE_URL_PROD= GUARDIAN_AUTH_KEY= \
        GOOGLE_TAG_MANAGER_ID= INFORMIZELY_SITE_ID= INFORMIZELY_ACCOUNT_DELETED_SURVEY_ID= \
  sh -c ' \
     bin/alerts_concierge eval ":crypto.supports()" && \
     bin/alerts_concierge eval ":ok = :public_key.cacerts_load"'

EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bin/alerts_concierge", "start"]
