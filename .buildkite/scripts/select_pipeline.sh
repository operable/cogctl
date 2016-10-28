#!/usr/bin/env bash

set -euo pipefail

if [ -z ${COG_BRANCH+notset} ]
then
    PIPELINE=.buildkite/standard_pipeline.yml
else
    echo "This is a triggered pipeline; running against the $COG_BRANCH branch of Cog"
    PIPELINE=.buildkite/triggered_pipeline.yml
fi

buildkite-agent pipeline upload ${PIPELINE} --replace
