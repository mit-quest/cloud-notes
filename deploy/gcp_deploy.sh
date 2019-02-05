#!/bin/bash

# TODO: ask for this ID
PROJECT_ID=$1

# Providing a default
ZONE="us-east4-a"

# Use the Prebuilt gcloud sdk container provided by Google.
docker pull google/cloud-sdk

# Login with the container. This will likely require user input.
docker run -it --name gcloud-config google/cloud-sdk gcloud auth login

# Common rerun command for gcloud commands inside of docker image
GCLOUD="docker run --rm -it --volumes-from gcloud-config google/cloud-sdk gcloud"

# Set the project to the provided project ID
$GCLOUD config set project $PROJECT_ID

# Enable the use of the container registry gcr.io
$GCLOUD services enable containerregistry.googleapis.com

# Add authentication information for docker to login to gcr.io
$GCLOUD auth configure-docker --project $PROJECT_ID

# Login to gcr.io
$GCLOUD auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

# Tag and push the image to the new gcr.io repository
docker tag ${APPLICATION} gcr.io/${PROJECT_ID}/${APPLICATION}:deployment
docker push gcr.io/${PROJECT_ID}/${APPLICATION}:deployment
