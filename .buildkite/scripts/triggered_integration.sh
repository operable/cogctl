#!/usr/bin/env bash

set -uo pipefail

echo -e "--- :git: Checking out cog @ branch \033[0;32m${COG_BRANCH}\033[0m"
rm -Rf local_cog
git clone --branch=$COG_BRANCH git@github.com:operable/cog.git local_cog

# Buildkite doesn't have native support for multi-file docker-compose
# runs, so we have to do it ourselves

# Generate a project name like Buildkite does, by removing the hyphens
# from the job ID
PROJECT_NAME=cogctl_triggered_${BUILDKITE_JOB_ID//-}
COMPOSE_ARGS="--file docker-compose.ci.yml --file docker-compose.cog.yml --project-name $PROJECT_NAME"

echo "--- :docker: Building Docker Images"
docker-compose $COMPOSE_ARGS build --pull

echo "--- :hammer: Running Integration Tests"
docker-compose $COMPOSE_ARGS run cogctl .buildkite/scripts/integration.sh
EXIT_STATUS=$?
if [ $EXIT_STATUS -ne 0 ]
then
    echo "--- :skull: The run failed!"
fi

echo "--- Cleaning up Docker containers"
# This is what Buildkite does with its native Docker support
docker-compose $COMPOSE_ARGS kill
docker-compose $COMPOSE_ARGS rm --force -v
docker-compose $COMPOSE_ARGS down

exit $EXIT_STATUS
