#!/bin/bash

set -euo pipefail

# TODO: externalize this name logic?
package_name=cogctl-${PLATFORM}-${BUILDKITE_BUILD_NUMBER}-${BUILDKITE_COMMIT}

echo "--- :package: Downloading ${package_name}"
buildkite-agent artifact download "${package_name}" .

# Remove the bin/cogctl script (which is Python, and is what
# pyinstaller uses to create the executable). Aruba always adds
# `./bin` to the beginning of the path, and we don't want the Python
# code to be running directly!
rm bin/cogctl

mv "${package_name}" bin/cogctl
chmod a+x bin/cogctl

echo "--- :eyes: Look, it works!"


docker run \
       --rm \
       --interactive \
       --tty \
       --volume "$(pwd)":/acceptance \
       --env PLATFORM="${PLATFORM}" \
       --env LC_ALL=C.UTF-8 \
       --env LANG=C.UTF-8 \
       --workdir /acceptance \
       "${IMAGE}" .buildkite/scripts/run_cucumber.sh
