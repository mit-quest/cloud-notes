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

trap finish EXIT

CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[@]}")

if [[ "$CONTAINS" = "ERROR" ]]; then
    echo $ARGUMENTS
    exit 1
fi

# Capture some variables in this shell's context that will be used in
# cloud specific deployment scripts.
export ESTABLISH_CONNECTION="return 1"
export JUPYTER_SERVER=""
export CONTAINER_NAME="${PROVIDER}-config"
export CONFIG_MOUNT=/.persistant_data
export RESOURCES=qi-bridge-transient-resources
export APPLICATION="cloud-notes"
export CR_IMAGE=${APPLICATION}:deployment

function PushToRemote()
{
    APP=$1
    REGISTRY=$2

    REMOTE_IMAGE=${REGISTRY}/${APP}:$(id -u -n $RUID)-deployment
    docker tag ${APP} ${REMOTE_IMAGE}
    docker push ${REMOTE_IMAGE} 
}

export -f PushToRemote

docker build . --build-arg USER_ID=$(id -u $USER) -t $APPLICATION
. ./bin/${PROVIDER}_deploy.sh

echo
echo "*** USE THE FOLLOWING URL TO CONNECT TO YOUR JUPYTER SERVER ***"
echo ${JUPYTER_SERVER}:8888
echo
read -n 1 -p "PRESS ENTER TO CONTINUE AND RETRIEVE YOUR TOKEN" input
echo

# Will exit with error by default
$ESTABLISH_CONNECTION
