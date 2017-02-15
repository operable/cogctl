#!/bin/bash

# TODO Need this in the image instead
if [ "${PLATFORM}" == "alpine" ]
then
    echo "--- Installing additional Alpine dependencies"
    apk -U add libffi-dev musl-dev gcc
fi

echo "--- :bundler: Install Dependencies"
bundle install

echo "--- :cucumber: Run cucumber tests"
cucumber
