#!/bin/bash
#
# Promote the platform-specific image we built earlier in the pipeline
# to our real cogctl Docker repository, tagged as a "master"
# image. This tag will "float"; only the most recent build will be
# present, and old builds will go away.

set -euo pipefail

tag=$(buildkite-agent meta-data get "${PLATFORM}-tag")

ci_image="operable/cogctl-testing:${tag}"
master_image="operable/cogctl:${PLATFORM}-master"

echo "--- Pulling ${ci_image}"
docker pull "${ci_image}"

echo "--- Re-tagging ${ci_image} to ${master_image}"
docker tag "${ci_image}" "${master_image}"

echo "--- Pushing  ${master_image}"
docker push "${master_image}"
