#!/bin/bash

set -e

finish()
{
    popd > /dev/null
    unset -f finish
}

pushd $(dirname $0) > /dev/null

trap finish SIGINT SIGTERM

# dockerfile is expected to be in the same directory
docker build . --build-arg USER_ID=$(id -u $USER) -t pynb-cloud

while IFS= read -r line; do
    echo "$line" | perl ./ipynb-url -
done < <(docker run -i -p 8888:8888 pynb-cloud 2>&1)

finish
