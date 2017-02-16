#!/bin/bash

set -euo pipefail

echo "--- :hammer_and_wrench: Build it!"

tag="${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}"
builder_container="operable/cogctl-testing:${tag}"

docker build \
       --tag "${builder_container}" \
       --label="git_commit=${BUILDKITE_COMMIT}" \
       --file Dockerfile."${PLATFORM}" .

mkdir output

docker run \
       --volume "$(pwd)"/output:/src/output \
       --rm \
       "${builder_container}" \
       cp /usr/bin/cogctl /src/output

echo "--- :package: Upload artifact"
package_name=cogctl-${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}
mv output/cogctl "${package_name}"
buildkite-agent artifact upload "${package_name}"

echo "--- :docker: Pushing ${builder_container}"
docker push "${builder_container}"

# Set metadata so we can figure out what image to promote to our real
# repository. See .buildkite/scripts/push_image.sh for more.
buildkite-agent meta-data set "${PLATFORM}-tag" "${tag}"
