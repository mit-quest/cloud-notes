#!/bin/bash

LOCATION="us-east4-a"
CLUSTER=qitransientcluster
REG_SERVER=gcr.io/${RESOURCES}

# Use the Prebuilt gcloud sdk container provided by Google.
docker pull google/cloud-sdk

# Login with the container. This will likely require user input.
docker run \
    -it \
    --name ${CONFIG} \
    google/cloud-sdk \
    gcloud auth login

# Common rerun commands for gcloud commands inside of docker image
PREFIX="docker run --rm --volumes-from ${CONFIG} google/cloud-sdk"
GCLOUD="$PREFIX gcloud"
KUBECTL="$PREFIX kubectl"

# Create a hosting project for transient resources.
$GCLOUD projects create $RESOURCES

$GCLOUD config set project $RESOURCES
$GCLOUD config set compute/zone $LOCATION

echo
echo CHOOSE A BILLING ACCOUNT TO LINK WITH "\"${RESOURCES}\""
let option_id=0
while IFS= read -r line; do
    let option_id++
    echo "[${option_id}] ${line}"
done < <(docker run \
    --rm \
    --volumes-from ${CONFIG} \
    google/cloud-sdk \
    gcloud beta billing accounts list \
    --format "table[no-heading](name,displayName)")

echo
read -n 1 -p "> " CHOICE
echo

let option_id=0
while IFS= read -r line; do
    let option_id++
    if [ "$option_id" = $CHOICE ]; then
        $GCLOUD alpha billing projects link $RESOURCES --billing-account $line
        break
    fi
done < <(docker run \
    --rm \
    --volumes-from ${CONFIG} \
    google/cloud-sdk \
    gcloud beta billing accounts list \
    --format "table[no-heading](name)")

# Enable the use of the container and the container registry APIs for project
$GCLOUD services enable containerregistry.googleapis.com
$GCLOUD services enable container.googleapis.com

# Add authentication information for docker to login to gcr.io
$GCLOUD auth configure-docker --project $RESOURCES --quiet

# Login to gcr.io
$GCLOUD auth print-access-token | docker login \
    -u oauth2accesstoken \
    --password-stdin https://gcr.io

# Tag and push the image to the new gcr.io repository
docker tag ${APPLICATION} ${REG_SERVER}/${CR_IMAGE}
docker push ${REG_SERVER}/${CR_IMAGE}

# Create a cluster to run the container
$GCLOUD container clusters delete $CLUSTER > /dev/null
$GCLOUD container clusters create $CLUSTER --num-nodes 1

$KUBECTL run ${APPLICATION} --image=${REG_SERVER}/${CR_IMAGE} --port=8888
$KUBECTL expose deployment ${APPLICATION} --port 8888 --target-port 8888
