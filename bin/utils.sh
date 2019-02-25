#!/bin/bash

if [ ! -x "$(command -v docker)" ]; then
    echo "\
An installation of docker is required. \
See https://docs.docker.com/install for installation instructions."

    exit 1
fi

# Get the absolute path to the working directory
pushd $(dirname $0) > /dev/null
export WORKDIR=$(pwd -P)
popd > /dev/null

PROVIDERS=(aws gcp az ibm local)
ARGUMENTS="please specify ONE of the following providers:[${PROVIDERS[*]}]"

if [ $# -ne 1 ]
then
    echo "arguments for $0: <CLOUD_PROVIDER>"
    echo $ARGUMENTS

    exit 1
fi

function IsWindows()
{
    if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo true
    else
        echo false
    fi

    return 0
}
