#!/bin/bash

LOCATION="us-east4-a"
CLUSTER=qitransientcluster
REG_SERVER=gcr.io/${RESOURCES}

# Use the Prebuilt gcloud sdk container provided by Google.
docker pull google/cloud-sdk

# Login with the container. This currently requires user interaction
# at the browser to complete. The below command creates a volume
# at the ${CONFIG_MOUNT} location in order to persist kubernetes
# login credentials by setting the KUBECONFIG environment variable.
#
docker run \
    -it \
    --name ${CONTAINER_NAME} \
    -e KUBECONFIG=${CONFIG_MOUNT}/kube_config \
    --mount type=volume,target=${CONFIG_MOUNT} \
    google/cloud-sdk \
    gcloud auth login

# Common docker command component for gcloud and kubectl commands inside
# of the google/cloud-sdk container.
#
PREFIX="docker run \
    --rm \
    -e KUBECONFIG=${CONFIG_MOUNT}/kube_config \
    --volumes-from ${CONTAINER_NAME} \
    google/cloud-sdk"

GCLOUD="$PREFIX gcloud"
KUBECTL="$PREFIX kubectl"

# Create a hosting project for transient resources.
$GCLOUD projects create $RESOURCES

$GCLOUD config set project $RESOURCES
$GCLOUD config set compute/zone $LOCATION

# GCP requires setting up billing on a project before certain services
# can be used. GCP does not automatically create a link to billing
# as the billing structure of GCP allows for many billing accounts within
# an organization.
echo
echo CHOOSE A BILLING ACCOUNT TO LINK WITH "\"${RESOURCES}\""

# Create a menu for billing account options.
let option_id=0
while IFS= read -r line; do
    let option_id++

    # Provide an options menu to select a billing account.
    echo "[${option_id}] ${line}"

# Lists all of the available billing accounts for the current user
# formatted to list the account number and the display name.
#
done < <(docker run \
    --rm \
    -e KUBECONFIG=${CONFIG_MOUNT}/kube_config \
    --volumes-from ${CONTAINER_NAME} \
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

# From the above user selection, link the billing account to the current project.
#
done < <(docker run \
    --rm \
    -e KUBECONFIG=${CONFIG_MOUNT}/kube_config \
    --volumes-from ${CONTAINER_NAME} \
    google/cloud-sdk \
    gcloud beta billing accounts list \
    --format "table[no-heading](name)")

# Enable the use of the container and the container registry APIs for project
$GCLOUD services enable containerregistry.googleapis.com
$GCLOUD services enable container.googleapis.com

# Add authentication information for docker to login to gcr.io
$GCLOUD auth configure-docker --project $RESOURCES

# Login to gcr.io
$GCLOUD auth print-access-token | docker login \
    -u oauth2accesstoken \
    --password-stdin https://gcr.io

# Tag and push the image to the new gcr.io repository
docker tag ${APPLICATION} ${REG_SERVER}/${CR_IMAGE}
docker push ${REG_SERVER}/${CR_IMAGE}

# Create a cluster to run the container
$GCLOUD container clusters create $CLUSTER \
    --num-nodes 1 \
    --enable-basic-auth \
    --no-enable-ip-alias \
    --metadata disable-legacy-endpoints=true \
    --network "default" \
    --issue-client-certificate \
    --scopes \
        compute-rw,storage-ro

$GCLOUD container clusters get-credentials $CLUSTER --zone ${LOCATION}

docker run \
    -ti \
    --rm \
    --volumes-from ${CONFIG} \
    google/cloud-sdk \
    gcloud auth application-default login

$KUBECTL run ${APPLICATION} \
    --image=${REG_SERVER}/${CR_IMAGE} \
    --server=https://${REG_SERVER} \
    --port 8080

$KUBECTL expose deployment ${APPLICATION} \
    --server=https://${REG_SERVER} \
    --port 8080 \
    --target-port 8080
