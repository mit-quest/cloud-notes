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
# docker but the persisted login credentials are still accesible acorss
# container instances.
#
# https://github.com/Azure/azure-cli-docker/issues/54

docker run -it --name $CONFIG -e AZURE_CONFIG_DIR=/$CONFIG --mount type=volume,target=/$CONFIG microsoft/azure-cli az login

AZ="docker run --rm -it -e AZURE_CONFIG_DIR=/$CONFIG --volumes-from $CONFIG microsoft/azure-cli az"

$AZ account set -s $SUBSCRIPTION_ID

# Should check for group existence here using `az group list`
# before clling `az group create [params]`
$AZ group create --name $RG --location $LOCATION

$AZ acr create --resource-group $RG --name $REGISTRY --sku Basic

# Can't use `az acr login` from docker container. This command requires
# an installation of docker to exist as it calls `docker ps` internally
# and then issues a `docker login` command
# $AZ acr login --name $REGISTRY

docker tag pynb-cloud ${REGISTRY}.azurecr.io/jupyter-server:deployment
docker push ${REGISTRY}.azurecr.io/jupyter-server:deployment
