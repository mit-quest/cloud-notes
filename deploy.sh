#!/bin/bash

PROVIDERS=(aws gcp az ibm local)
ARGUMENTS="please specify ONE of the following providers:[${PROVIDERS[*]}]"

if [ $# -ne 1 ]
then
    echo "arguments for $0: <CLOUD_PROVIDER>"
    echo $ARGUMENTS

    exit 1
fi

if [ ! -x "$(command -v docker)" ]; then
    echo \
"An installation of docker is required. \
See https://docs.docker.com/install for installation instructions."

    exit 1
fi

PROVIDER=$1

# Get the absolute path to the working directory
pushd $(dirname $0) > /dev/null
export WORKDIR=$(pwd -P)
popd > /dev/null

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

# Tags and pushes an image to a remote registry.
# ARGUMENTS:
#   LOCAL_IMAGE - Docker image name on the local machine
#   REGISTRY    - The remote Container Registry URL
#.
# Returns: the remote image name as REMOTE_IMAGE.
#
function PushToRemote()
{
    LOCAL_IMAGE=$1
    REGISTRY=$2

    REMOTE_IMAGE="${REGISTRY}/${LOCAL_IMAGE}:dep.$(id -u -n $RUID)"

    docker tag ${LOCAL_IMAGE} ${REMOTE_IMAGE} > /dev/null
    docker push ${REMOTE_IMAGE} > /dev/null

    echo ${REMOTE_IMAGE}
}

export -f PushToRemote

function contains()
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
