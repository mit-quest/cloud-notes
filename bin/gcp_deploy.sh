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
accounts=()
while IFS= read -r line; do
    let option_id++

    # Provide an options menu to select a billing account.
    echo "[${option_id}] ${line}"
    account_id="${line%% *}"
    accounts+=("$account_id")

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

let CHOICE--

$GCLOUD alpha billing projects link $RESOURCES --billing-account ${accounts[CHOICE]}

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

K8S_ENDPOINT=$($GCLOUD container clusters describe $CLUSTER \
    --format="table[no-heading](endpoint)")

DEPLOYMENT=${APPLICATION}-deployment
APPSERVICE=${APPLICATION}-service

$KUBECTL run \
    $DEPLOYMENT \
    --image=${REG_SERVER}/${CR_IMAGE} \
    --server=${K8S_SERVER} \
    --port 8888

$KUBECTL expose deployment \
    ${DEPLOYMENT} \
    --name ${APPSERVICE} \
    --type=LoadBalancer \
    --server=${K8S_SERVER} \
    --port 8888 \
    --target-port 8888

# Get the IP Address of the exposed Jupyter notebook service running
# in the kubernetes cluster
while [ -z "$JUPYTER_SERVER" ]; do
    JUPYTER_SERVER=$($KUBECTL \
        get services $APPSERVICE \
        -o=custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress..ip \
        --no-headers)

    # Querying for the external IP immediately after setting up a service
    # in Kubernetes will sometimes result in the external IP not being set
    # and the query will return "<none>"
    #
    if [ "<none>" = "$JUPYTER_SERVER" ]; then
        JUPYTER_SERVER=
    fi
done

JUPYTER_POD=$($KUBECTL \
    get pods \
    -o=custom-columns=NAME:.metadata.name \
    --no-headers)

ESTABLISH_CONNECTION="$KUBECTL logs -f $JUPYTER_POD"
