#!/bin/bash

set -euo pipefail

echo "--- :hammer_and_wrench: Build it!"

builder_container=cogctl-builder${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}
docker build \
       --tag "${builder_container}" \
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
