#!/usr/bin/env bash

set -euo pipefail

COG_TIMEOUT=90

if [ "$BUILDKITE_SOURCE" == "trigger_job" ]
then
    # COG_IMAGE gets sent over in the trigger payload
cat <<EOF
steps:
  - command: .buildkite/scripts/wait-for-it.sh cog:4000 -s -t ${COG_TIMEOUT} -- mix test --only=external
    label: ":cogops: Integration Tests Against ${COG_IMAGE}"
    agents:
      queue: beta
    plugins:
      docker-compose:
        run: cogctl
        config:
          - docker-compose.ci.yml
          - docker-compose.ci.triggered.yml
EOF

else
    # "Normal" Config
    cat <<EOF
steps:
  - label: ":docker: Build Test Image"
    agents:
      queue: beta # TODO: dedicated builder queue
    plugins:
      docker-compose:
        build: test
        image_repository: "index.docker.io/operable/cogctl-testing"
        config: docker-compose.test.yml

  - wait

  - label: ":elixir: Escript Build"
    command: "mix escript"
    env:
      MIX_ENV: prod
    agents:
      queue: beta
    plugins:
      docker-compose:
        run: test
        config: docker-compose.test.yml

  - label: ":elixir: Unit Tests"
    command: "mix test --exclude=external"
    env:
      MIX_ENV: test
    agents:
      queue: beta
    plugins:
      docker-compose:
        run: test
        config: docker-compose.test.yml

  - label: ":elixir: Integration Tests"
    command: .buildkite/scripts/wait-for-it.sh cog:4000 -s -t ${COG_TIMEOUT} -- mix test --only=external
    plugins:
      docker-compose:
        run: cogctl
        config: docker-compose.ci.yml
    agents:
      queue: beta
EOF
fi
