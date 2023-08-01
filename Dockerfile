ARG ELIXIR_VERSION=1.14.3
ARG ERLANG_VERSION=25.2.1
ARG ALPINE_VERSION=3.18.0

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} as build

ENV MIX_ENV=prod

RUN mkdir /trike

WORKDIR /trike

RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config/config.exs config/config.exs
COPY config/prod.exs config/prod.exs

RUN mix deps.compile

COPY lib lib
COPY config/runtime.exs config/runtime.exs
RUN mix release linux

# The one the elixir image was built with
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache libssl1.1 dumb-init libstdc++ libgcc ncurses-libs && \
    mkdir /work /trike && \
    adduser -D trike && chown trike /work

COPY --from=build /trike/_build/prod/rel/linux /trike

# Allow Trike to update the Timezone data
RUN chown trike /trike/lib/tzdata-*/priv /trike/lib/tzdata*/priv/*

# Set exposed ports
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 \
    ERL_CRASH_DUMP_SECONDS=0 RELEASE_TMP=/work

USER trike
WORKDIR /work

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

HEALTHCHECK CMD ["/trike/bin/linux", "rpc", "1 + 1"]
CMD ["/trike/bin/linux", "start"]
