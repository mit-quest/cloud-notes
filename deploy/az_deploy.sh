#!/bin/bash

# Get access to the Azure CLI
docker pull microsoft/azure-cli

CONFIG=azure-config
LOCATION=eastus
RG=qi-bridge-transient-deploy-rg
REGISTRY=qitransientregistry

SUBSCRIPTION_ID=$1

# The Azure CLI container does not provide an automatic mount point
# for it's credentials. Thes requires a little extra manual work through
# docker but the persisted login credentials are still accesible across
# container instances.
#
# https://github.com/Azure/azure-cli-docker/issues/54

docker run -it --name $CONFIG -e AZURE_CONFIG_DIR=/$CONFIG --mount type=volume,target=/$CONFIG microsoft/azure-cli az login

# Reusable az command to mask the docker commands.
AZ="docker run --rm -it -e AZURE_CONFIG_DIR=/$CONFIG --volumes-from $CONFIG microsoft/azure-cli az"

# Should check for group existence here using `az group list`
# before calling `az group create [params]` but azure seems to ignore
# commands issued to create resources that already exist.
$AZ group create --name $RG --location $LOCATION

$AZ acr create --resource-group $RG --name $REGISTRY --sku Basic

# Can't use `az acr login` from docker container. This command requires
# an installation of docker to exist as it calls `docker ps` internally
# and then issues a `docker login` command, setting admin enabled
# $AZ acr login --name $REGISTRY
$AZ acr update --name $REGISTRY --admin-enabled true

# Get the admin username and password from the Azure Container Registry
# and issue a docker login command for the acr.
USERNAME=$($AZ acr credential show --name $REGISTRY --query username)
$AZ acr credential show --name $REGISTRY --query passwords[0].value | \
    docker login -u $USERNAME --password-stdin ${REGISTRY}.azurecr.io

docker tag pynb-cloud ${REGISTRY}.azurecr.io/jupyter-server:deployment
docker push ${REGISTRY}.azurecr.io/jupyter-server:deployment
