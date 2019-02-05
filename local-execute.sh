#!/bin/bash

set -e

APPLICATION="cloud-notes"

finish()
{
    popd > /dev/null
    unset APPLICATION
    unset -f finish
}

pushd $(dirname $0) > /dev/null
export MOUNTSOURCE=$(pwd)

trap finish SIGINT SIGTERM

# dockerfile is expected to be in the same directory
docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION

while IFS= read -r line; do
    echo "$line" | perl ./ipynb-url -
done < <(docker run \
    --rm \
    -i \
    -p 8888:8888 \
    --mount type=bind,source="${MOUNTSOURCE}/workspace",target="/workspace" \
    $APPLICATION 2>&1)

finish
