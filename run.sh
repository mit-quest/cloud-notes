#!/bin/bash

set -e

# Import our utility functions
. $(dirname $0)/bin/utils.sh

trap UnsetUtils EXIT

RequireDocker
PermissionsCheck

if ! [ $# = 1 ]; then
    echo "USE: $0 <PROVIDER>" 1>&2
    exit 1
fi

PROVIDER=$1
CheckProvider $PROVIDER
APPLICAITION=$(GetContainerName "cloud-notes" $PROVIDER)

WORKDIR=$(GetAbsPath $0)

if [ -z "${PROVIDER/local/}" ]; then
    export MOUNTSOURCE="${WORKDIR}/workspace"
else
    export ESTABLISH_CONNECTION="exit 1"
    export JUPYTER_SERVER=""
fi

function finish()
{
    unset ESTABLISH_CONNECTION
    unset JUPYTER_SERVER
    unset CONTAINER_NAME
    unset CONFIG_MOUNT
    unset RESOURCES
    unset APPLICATION

    unset -f contains
    unset -f finish
    unset -f PushToRemote
}

trap finish EXIT

. ${WORKDIR}/bin/build
. ${WORKDIR}/bin/${PROVIDER}

if [ ! -z ${PROVIDER/local/} ]; then
    echo
    echo "*** USE THE FOLLOWING URL TO CONNECT TO YOUR JUPYTER SERVER ***"
    echo ${JUPYTER_SERVER}:8888
    echo
    read -n 1 -p "PRESS ENTER TO CONTINUE AND RETRIEVE YOUR TOKEN" input
    echo

    # Will exit with error by default
    $ESTABLISH_CONNECTION
fi
