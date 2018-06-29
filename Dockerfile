FROM erlang:20 as builder

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.6.5" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="defe2bed953ee729addf1121db3fa42a618ef1d6c57a1f489da03b0e7a626e89" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/local/src/elixir \
	&& tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
	&& rm elixir-src.tar.gz \
	&& cd /usr/local/src/elixir \
	&& make install clean

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
