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

trap finish SIGINT SIGTERM


# dockerfile is expected to be in the same directory
docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION

while IFS= read -r line; do
    echo "$line" | perl ./ipynb-url -
done < <(docker run -i -p 8888:8888 $APPLICATION 2>&1)

finish
