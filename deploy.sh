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
    for element; do [[ "$element" == "$match" ]] && return 0; done
    return 1
}

finish()
{
    popd > /dev/null
    unset -f contains
    unset -f finish
}

pushd $(dirname $0) > /dev/null

trap finish SIGINT SIGTERM

# dockerfile is expected to be in the same directory
docker build . --build-arg USER_ID=$(id -u $USER) -t pynb-cloud

# The docker image responsible for provisioning resources
# might need to be built with the --network=host command

# Need to determine how to push to a container registry within
# each cloud platform using their CLI?
CONTAINS=$(contains "$PROVIDER" "${PROVIDERS[*]}")
./deploy/${PROVIDER}_deploy.sh

# Ideally this is created on the fly and the required login credentials
# can be used to use a docker login command and push to the new registry.
# After the container is deployed we launch a deployment for the app
# using the container we just uploaded to the registry and it runs remotely.

# e.g.
# <cloud-cli> <create-registry>
# docker login <cloud-registry>
# docker tag pynb-cloud <cloud-registry>/pynb-server
# docker push <cloud-registry>/pynb-server

while IFS= read -r line; do
    echo "$line" | perl ./ipynb-url -
done < <(docker run -i -p 8888:8888 pynb-cloud 2>&1)

finish
