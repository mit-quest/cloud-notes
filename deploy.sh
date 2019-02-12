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
            return 0
        fi
    done
    echo "ERROR"
    return 1
}

finish()
{
    popd > /dev/null
    unset -f contains
    unset -f finish
}

pushd $(dirname $0) > /dev/null

trap finish SIGINT SIGTERM EXIT

CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[@]}")

if [[ "$CONTAINS" = "ERROR" ]]; then
    echo $ARGUMENTS
    exit 1
fi

# Capture some variables in this shell's context that will be used in
# cloud specific deployment scripts.
export ESTABLISH_CONNECTION="finish && return 1"
export CONTAINER_NAME="${PROVIDER}-config"
export CONFIG_MOUNT=/.persistant_data
export RESOURCES=qi-bridge-transient-resources
export APPLICATION="cloud-notes"
export CR_IMAGE=${APPLICATION}:deployment

docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION
. ./bin/${PROVIDER}_deploy.sh

# Will exit with error by default
$ESTABLISH_CONNECTION
