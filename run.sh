#!/bin/bash

PROVIDER=$1

# Capture some variables in this shell's context that will be used in
# cloud specific deployment scripts.
export CONTAINER_NAME="${PROVIDER}-config"
export CONFIG_MOUNT=/.persistant_data
export RESOURCES="$(id -u -n $RUID)-transient-resources"

# Manipulate the container name to include "-local" as a subscript if
# running locally.
#
export APPLICATION=cloud-notes$(if [ -z "${PROVIDER/local/}" ]; then echo -${PROVIDER}; fi)

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

CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[@]}")

if [[ "$CONTAINS" = "ERROR" ]]; then
    echo $ARGUMENTS
    exit 1
fi

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
