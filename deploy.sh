#!/bin/bash

PROVIDERS=(aws gcp az ibm)
ARGUMENTS="please specify ONE of the following providers:[${PROVIDERS[*]}]"

if [ $# -ne 1 ]
then
    echo "arguments for $0: <CLOUD_PROVIDER>"
    echo $ARGUMENTS
    exit 1
fi

PROVIDER=$1

contains()
{
    local element match="$1"
    shift
    for element
    do
        if [[ "$element" == "$match" ]]; then
            echo "SUCCESS"
            return 1
        fi
    done
    echo "ERROR"
    return 0
}

finish()
{
    popd > /dev/null
    unset -f contains
    unset -f finish
}

pushd $(dirname $0) > /dev/null

trap finish SIGINT SIGTERM

CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[@]}")

if [[ "$CONTAINS" = "ERROR" ]]; then
    echo $ARGUMENTS
    exit 1
fi

# Used in deploy scripts
export APPLICATION="cloud-notes"

# Build the dockerfile for the development context
docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION

# Capture some variables in this shell's context
export ESTABLISH_CONNECTION="finish && return 1"
export CONFIG="${PROVIDER}-config"
. ./deploy/${PROVIDER}_deploy.sh

# Will return error by default
$ESTABLISH_CONNECTION

finish
