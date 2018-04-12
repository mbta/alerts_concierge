FROM elixir:1.6 as builder

ENV MIX_ENV=prod

WORKDIR /root
ADD . .

# Configure Git to use HTTPS in order to avoid issues with the internal MBTA network
RUN git config --global url.https://github.com/.insteadOf git://github.com/

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix do deps.get --only prod, compile --force

WORKDIR /root/apps/concierge_site/assets/
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g brunch && \
    npm install -g yarn
RUN yarn install
RUN brunch build --production

WORKDIR /root/apps/concierge_site/
RUN mix phx.digest

WORKDIR /root
RUN mix release --verbose

#### Here we go: multi-stage docker, no need for builder pattern! ####
# the one the elixir image was built with
FROM debian:stretch

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl1.1 libsctp1 curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root
EXPOSE 4000
ENV MIX_ENV=prod TERM=xterm LANG="C.UTF-8" REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/alerts_concierge/releases/current/alerts_concierge.tar.gz .
RUN mkdir gtfs
RUN tar -xzf alerts_concierge.tar.gz
CMD ["bin/alerts_concierge", "foreground"]
