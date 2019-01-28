#!/bin/bash

# Get access to the Azure CLI
docker pull microsoft/azure-cli

CONFIG=azure-config
LOCATION=eastus

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

# Should check for group existence here using `az group list` before group creation.
$AZ group create --name qi-bridge-transient-deploy-rg --location $LOCATION
