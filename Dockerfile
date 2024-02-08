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

RUN apt-get install --no-install-recommends --yes curl

WORKDIR /root/apps/concierge_site/priv/static
COPY --from=asset-builder /root/apps/concierge_site/priv/static .

WORKDIR /root
RUN curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
  -o aws-cert-bundle.pem
RUN echo "51b107da46717aed974d97464b63f7357b220fe8737969db1492d1cae74b3947  aws-cert-bundle.pem" | sha256sum -c -
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
COPY --from=app-builder /root/aws-cert-bundle.pem ./priv/aws-cert-bundle.pem

EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bin/alerts_concierge", "start"]
