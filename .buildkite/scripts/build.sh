#!/bin/bash

set -euo pipefail

echo "--- :hammer_and_wrench: Build it!"
scripts/write-git-sha

builder_container=cogctl-builder${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}
docker build \
       --tag "${builder_container}" \
       --file Dockerfile."${PLATFORM}" .

mkdir dist

docker run \
       --volume "$(pwd)"/dist:/src/dist \
       --rm \
       "${builder_container}" \
       pyinstaller --onefile --add-data cogctl/GITSHA:. bin/cogctl

echo "--- :package: Upload artifact"
package_name=cogctl-${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}
mv dist/cogctl "${package_name}"
buildkite-agent artifact upload "${package_name}"
