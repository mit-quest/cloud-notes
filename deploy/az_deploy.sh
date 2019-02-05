#!/bin/bash

# Get access to the Azure CLI
docker pull microsoft/azure-cli

LOCATION=eastus
RG=qi-bridge-transient-deploy-rg
REGISTRY=qitransientregistry
REG_SERVER=${REGISTRY}.azurecr.io

# az cli leaves junk in the output when calling az methods with --query
TrimQuery() {
    INPUT=$1
    echo ${INPUT: 1: -2}
}

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
# and then issues a `docker login` command. Instead setting admin enabled
# to login with the ACR admin credential.
$AZ acr update --name $REGISTRY --admin-enabled true

# Get the admin username and password from the Azure Container Registry
# and issue a docker login command for the ACR.
ACR_USERNAME=$(TrimQuery "$($AZ acr credential show --name $REGISTRY --query username)")
ACR_PASSWORD=$(TrimQuery "$($AZ acr credential show --name $REGISTRY --query passwords[0].value)")

echo $ACR_PASSWORD | docker login -u $ACR_USERNAME --password-stdin https://${REG_SERVER}

docker tag pynb-cloud ${REG_SERVER}/${APPLICATION}:deployment
docker push ${REG_SERVER}/${APPLICATION}:deployment

# Create and deploy a container instance in Azure.
DNS_NAME_LABEL=${APPLICATION}-${RANDOM}${RANDOM}
$AZ container create \
    --name ${APPLICATION} \
    --resource-group $RG \
    --image ${REG_SERVER}/${APPLICATION}:deployment \
    --registry-login-server ${REG_SERVER} \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --ip-address public \
    --ports 8888\
    --dns-name ${DNS_NAME_LABEL}

echo
echo "Listening to: $FQDN:80"
