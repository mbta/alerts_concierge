FROM erlang:22.3.4.14 as builder

# elixir expects utf8.
ENV ELIXIR_VERSION=1.8.2 \
	ELIXIR_SHA1=62265bb3660bfc17a1ad209be9ca9304ae9d3035 \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VERSION}.tar.gz" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_SHA1 elixir-src.tar.gz" | sha1sum -c - \
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
	apt-get install -y nodejs npm && \
	npm install -g yarn
RUN yarn install
RUN yarn run deploy

WORKDIR /root/apps/concierge_site/
RUN mix phx.digest

WORKDIR /root
RUN mix release --verbose

# the one the elixir image was built with
FROM debian:buster

RUN apt-get update && apt-get install -y --no-install-recommends \
	libssl1.1 libsctp1 libtinfo6 curl \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /root
EXPOSE 4000
ENV MIX_ENV=prod TERM=xterm LANG="C.UTF-8" REPLACE_OS_VARS=true

COPY --from=builder /root/_build/prod/rel/alerts_concierge/releases/current/alerts_concierge.tar.gz .
RUN mkdir gtfs
RUN tar -xzf alerts_concierge.tar.gz
CMD ["bin/alerts_concierge", "foreground"]
