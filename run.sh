#!/bin/bash

# Import our utility functions
. $(dirname $0)/bin/utils.sh

trap UnsetUtils EXIT

RequireDocker
PermissionsCheck

if ! [ $# = 3 ]; then
    echo "USE: $0 <WORKSPACE> <DATA> <PROVIDER>" 1>&2
    exit 1
fi

PROVIDER=$1
CheckProvider $PROVIDER

export APPLICATION=$(GetContainerName "cloud-notes" $PROVIDER)
export WORKDIR=$(GetAbsPath $0)
export ESTABLISH_CONNECTION=""
export JUPYTER_SERVER=""

function finish()
{
    unset APPLICATION
    unset WORKDIR
    unset ESTABLISH_CONNECTION
    unset JUPYTER_SERVER

    unset -f finish
}

trap finish EXIT

. ${WORKDIR}/bin/build
. ${WORKDIR}/bin/deploy ${PROVIDER}

if ! typeset -f ConnectToServer >/dev/null; then
    echo "An error occurred during deployment and no Jupyter server was found." >&2
    exit 1
fi

if [ ! -z ${PROVIDER/local/} ]; then
    echo
    echo "*** USE THE FOLLOWING URL TO CONNECT TO YOUR JUPYTER SERVER ***"
    echo ${JUPYTER_SERVER}:8888
    echo
    read -n 1 -p "PRESS ENTER TO CONTINUE AND RETRIEVE YOUR TOKEN" input
    echo

    trap \
        'echo "\nTerminating connection to host. Server will continue running remotely"' SIGINT
fi

ConnectToServer
