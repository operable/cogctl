FROM operable/elixir:1.3.4-r0

COPY mix.exs mix.lock /tmp/cogctl-build/
WORKDIR /tmp/cogctl-build

RUN mix do deps.get, deps.compile
COPY config config
COPY lib lib
RUN mix escript && \
    cp /tmp/cogctl-build/cogctl /usr/local/bin/cogctl && \
    cd /root && \
    rm -Rf /tmp/cogctl-build

WORKDIR /root

VOLUME /root/.cogctl

ENTRYPOINT ["cogctl"]
