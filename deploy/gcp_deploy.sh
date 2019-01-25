#!/bin/bash

# Will probably need to ask for this ID
PROJECT_ID=$1

# Use the Prebuilt gcloud sdk container provided by Google.
docker pull google/cloud-sdk

# Login with the container. This will likely require user input.
docker run -it --name gcloud-config google/cloud-sdk gcloud login

# Common rerun command for gcloud commands inside of docker image
GCLOUD=docker run --rm --it --volumes-from gcloud-config gcloud

# Set the project to the provided project ID
$GCLOUD config set project $PROJECT_ID

# Enable the use of the container registry gcr.io
$GCLOUD services enable containerregistry.googleapis.com

# Add authentication information for docker to login to gcr.io
$GCLOUD auth configure-docker --project $PROJECT_ID

# Login to gcr.io
$GCLOUD auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

docker tag pynb-cloud gcr.io/$PROJECT_ID/jupyter-server
