#!/bin/bash

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

export CONFIG_MOUNT=/.persistant_data
export RESOURCES="$(id -u -n $RUID)-transient-resources"
export CONTAINER_NAME="${PROVIDER}-config"
