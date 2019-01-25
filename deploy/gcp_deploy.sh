#!/bin/bash

PROJECT_ID=$1
GCLOUD=docker run --rm --it --volumes-from gcloud-config gcloud

docker pull google/cloud-sdk
docker run -it --name gcloud-config google/cloud-sdk gcloud login
$GCLOUD config set project $PROJECT_ID
$GCLOUD services enable containerregistry.googleapis.com
$GCLOUD auth configure-docker --project $PROJECT_ID
$GCLOUD auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

docker tag pynb-cloud gcr.io/$PROJECT_ID/jupyter-server
