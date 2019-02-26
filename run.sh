#!/bin/bash

# Setup logging
# print to >&3 for stdout
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3 RETURN
exec 1>"$0-$(date +%s)".log 2>&1

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

export APPLICATION=$(GetContainerName "cloud-notes" $PROVIDER)
export WORKDIR=$(GetAbsPath $0)
export MOUNTSOURCE="${WORKDIR}/workspace"
export ESTABLISH_CONNECTION="exit 1"
export JUPYTER_SERVER=""

function finish()
{
    unset APPLICATION
    unset WORKDIR
    unset MOUNTSOURCE
    unset ESTABLISH_CONNECTION
    unset JUPYTER_SERVER

    unset -f finish
}

trap finish EXIT

. ${WORKDIR}/bin/build
. ${WORKDIR}/bin/deploy.sh ${PROVIDER}

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
