FROM operable/docker-base

# Setup Mix Environment to use. We declare the MIX_ENV at build time
ARG MIX_ENV
ENV MIX_ENV ${MIX_ENV:-dev}

# Setup folder structure and copy code
RUN mkdir -p /home/operable/cogctl
COPY . /home/operable/cogctl/
WORKDIR /home/operable/cogctl

# Compile
RUN mix escript

ENTRYPOINT ./cogctl
