#!/bin/bash

LOCATION=eastus
REGISTRY=qitransientregistry
REG_SERVER=${REGISTRY}.azurecr.io

# Cleanup function to remove trailing characters in Azure CLI's
# --query output
TrimQuery() {
    INPUT=$1
    echo ${INPUT: 1: -2}
}

# Use the prebuilt Azure Cli container Provided by Microsoft
docker pull microsoft/azure-cli

# The Azure CLI container does not provide an automatic mount point
# for it's credentials. Thes requires a little extra manual work through
# docker but the persisted login credentials are still accesible across
# container instances.
#
# https://github.com/Azure/azure-cli-docker/issues/54
#
docker run \
    -it \
    --name ${CONTAINER_NAME} \
    -e AZURE_CONFIG_DIR=${CONFIG_MOUNT} \
    --mount type=volume,target=${CONFIG_MOUNT} \
    microsoft/azure-cli \
    az login

# Reusable AZ command to mask the use of docker.
AZ="docker run --rm -it -e AZURE_CONFIG_DIR=${CONFIG_MOUNT} --volumes-from ${CONTAINER_NAME} microsoft/azure-cli az"

# Create a resource group to host transient resoureces.
$AZ group create --name $RESOURCES --location $LOCATION
$AZ acr create --resource-group $RESOURCES --name $REGISTRY --sku Basic

# Can't use `az acr login` from docker container. This command requires
# an installation of docker to exist as it calls `docker ps` internally
# and then issues a `docker login` command. Instead setting admin enabled
# to login with the ACR admin credential.
#
$AZ acr update --name $REGISTRY --admin-enabled true

# Get the admin username and password from the Azure Container Registry
# by querying for the data using `az acr credential show`
#
ACR_USERNAME=$(TrimQuery "$($AZ acr credential show --name $REGISTRY --query username)")
ACR_PASSWORD=$(TrimQuery "$($AZ acr credential show --name $REGISTRY --query passwords[0].value)")

# Login to the privte Azure Container Registry with Docker.
echo $ACR_PASSWORD | docker login -u $ACR_USERNAME --password-stdin https://${REG_SERVER}

PushToRemote ${APPLICATION} ${REG_SERVER}

# Create and deploy a container instance in Azure.
DNS_NAME_LABEL=${APPLICATION}-${RANDOM}${RANDOM}
$AZ container create \
    --name ${APPLICATION} \
    --resource-group $RESOURCES \
    --image ${REG_SERVER}/${APPLICATION}:deployment \
    --registry-login-server ${REG_SERVER} \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --ip-address public \
    --ports 8888\
    --dns-name ${DNS_NAME_LABEL}

JUPYTER_SERVER=$(TrimQuery \
    "$($AZ container show --resource-group $RESOURCES --name $APPLICATION --query ipAddress.fqdn)")

ESTABLISH_CONNECTION="$AZ container attach --resource-group $RESOURCES --name $APPLICATION"
