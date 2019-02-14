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

# Capture some variables in this shell's context that will be used in
# cloud specific deployment scripts.
export ESTABLISH_CONNECTION="exit 1"
export JUPYTER_SERVER=""
export CONTAINER_NAME="${PROVIDER}-config"
export CONFIG_MOUNT=/.persistant_data
export RESOURCES=$(id -u -n $RUID)-transient-resources
export APPLICATION="cloud-notes"

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

    REMOTE_IMAGE=${REGISTRY}/${LOCAL_IMAGE}:$(id -u -n $RUID)-deployment
    docker tag ${LOCAL_IMAGE} ${REMOTE_IMAGE}
    docker push ${REMOTE_IMAGE} 

    echo $REMOTE_IMAGE
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
    popd > /dev/null

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

pushd $(dirname $0) > /dev/null

trap finish EXIT

CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[@]}")

if [[ "$CONTAINS" = "ERROR" ]]; then
    echo $ARGUMENTS
    exit 1
fi

docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION
. ./bin/${PROVIDER}

echo
echo "*** USE THE FOLLOWING URL TO CONNECT TO YOUR JUPYTER SERVER ***"
echo ${JUPYTER_SERVER}:8888
echo
read -n 1 -p "PRESS ENTER TO CONTINUE AND RETRIEVE YOUR TOKEN" input
echo

# Will exit with error by default
$ESTABLISH_CONNECTION
