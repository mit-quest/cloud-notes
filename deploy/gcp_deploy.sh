#!/bin/bash

# TODO: ask for this ID
PROJECT_ID=$1

CLUSTER=qitransientcluster

# Providing a default
ZONE="us-east4-a"

# Use the Prebuilt gcloud sdk container provided by Google.
docker pull google/cloud-sdk

# Login with the container. This will likely require user input.
docker run -it --name gcloud-config google/cloud-sdk gcloud auth login

# Common rerun commands for gcloud commands inside of docker image
PREFIX="docker run --rm -it --volumes-from gcloud-config google/cloud-sdk"
GCLOUD="$PREFIX gcloud"
KUBCTL="$PREFIX kubctl"

# Set the project to the provided project ID
$GCLOUD config set project $PROJECT_ID

# Enable the use of the container registry gcr.io
$GCLOUD services enable containerregistry.googleapis.com

# Add authentication information for docker to login to gcr.io
$GCLOUD auth configure-docker --project $PROJECT_ID

# Login to gcr.io
$GCLOUD auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

GCR_IMAGE=gcr.io/${PROJECT_ID}/${APPLICATION}:deployment

# Tag and push the image to the new gcr.io repository
docker tag ${APPLICATION} ${GCR_IMAGE}
docker push ${GCR_IMAGE}

# Create a cluster to run the container
$GCLOUD clusters create $CLUSTER --num-nodes 1

$KUBECTL run ${APPLICATION} --image ${GCR_IMAGE} --port 8888
$KUBECTL expose deployment ${APPLICATION} --port 8888 --target-port 8888
