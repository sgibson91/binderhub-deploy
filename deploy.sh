#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -e

## Detection of the deploy mode
#
# This script should handle both interactive deployment when run by a user
# on their local system, and also running as a container entrypoint when
# used either for a container-based local deployment or when deployed via an
# Azure blue button setup.
#
# Check whether BINDERHUB_CONTAINER_MODE is set, and if so assume running
# as a container-based install, checking that all required input is present
# in the form of environment variables

if [ ! -z $BINDERHUB_CONTAINER_MODE ] ; then
  echo "--> Deployment operating in container mode"
  echo "--> Checking required environment variables"
  # Set out a list of required variables for this script
  REQUIREDVARS=" \
          SP_APP_ID \
          SP_APP_KEY \
          SP_TENANT_ID \
          RESOURCE_GROUP_NAME \
          RESOURCE_GROUP_LOCATION \
          AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
          AKS_NODE_COUNT \
          AKS_NODE_VM_SIZE \
          CONTACT_EMAIL \
          DOCKER_USERNAME \
          DOCKER_PASSWORD \
          DOCKER_IMAGE_PREFIX \
          DOCKER_ORGANISATION \
          "
  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] ; then
      echo "--> ${required_var} must be set for container-based setup" >&2
      exit 1
    fi
  done

  # Azure blue-button prepends '/subscription/' to AZURE_SUBSCRIPTION
  AZURE_SUBSCRIPTION=$(echo $AZURE_SUBSCRIPTION | sed -r "s/^\/subscriptions\///")

else

  # Read in config file and assign variables for the non-container case
  configFile='config.json'

  echo "--> Reading configuration from ${configFile}"

  AZURE_SUBSCRIPTION=`jq -r '.azure .subscription' ${configFile}`
  BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
  BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`
  CONTACT_EMAIL=`jq -r '.binderhub .contact_email' ${configFile}`
  RESOURCE_GROUP_LOCATION=`jq -r '.azure .location' ${configFile}`
  RESOURCE_GROUP_NAME=`jq -r '.azure .res_grp_name' ${configFile}`
  AKS_NODE_COUNT=`jq -r '.azure .node_count' ${configFile}`
  AKS_NODE_VM_SIZE=`jq -r '.azure .vm_size' ${configFile}`
  SP_APP_ID=`jq -r '.azure .sp_app_id' ${configFile}`
  SP_APP_KEY=`jq -r '.azure .sp_app_key' ${configFile}`
  SP_TENANT_ID=`jq -r '.azure .sp_tenant_id' ${configFile}`
  DOCKER_USERNAME=`jq -r '.docker .username' ${configFile}`
  DOCKER_PASSWORD=`jq -r '.docker .password' ${configFile}`
  DOCKER_IMAGE_PREFIX=`jq -r '.docker .image_prefix' ${configFile}`
  DOCKER_ORGANISATION=`jq -r '.docker .org' ${configFile}`

  # Check that the variables are all set non-zero, non-null
  REQUIREDVARS=" \
          RESOURCE_GROUP_NAME \
          RESOURCE_GROUP_LOCATION \
          AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
          AKS_NODE_COUNT \
          AKS_NODE_VM_SIZE \
          CONTACT_EMAIL \
          DOCKER_IMAGE_PREFIX \
          "
  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] || [ x${required_var} == 'xnull' ] ; then
      echo "--> ${required_var} must be set for deployment" >&2
      exit 1
    fi
  done

  # Check if any optional variables are set null; if so, reset them to a
  # zero-length string for later checks. If they failed to read at all,
  # possibly due to an invalid json file, they will be returned as a
  # zero-length string -- this is attempting to make the 'not set'
  # value the same in either case.
  if [ x${SP_APP_ID} == 'xnull' ] ; then SP_APP_ID='' ; fi
  if [ x${SP_APP_KEY} == 'xnull' ] ; then SP_APP_KEY='' ; fi
  if [ x${SP_TENANT_ID} == 'xnull' ] ; then SP_TENANT_ID='' ; fi
  if [ x${DOCKER_USERNAME} == 'xnull' ] ; then DOCKER_USERNAME='' ; fi
  if [ x${DOCKER_PASSWORD} == 'xnull' ] ; then DOCKER_PASSWORD='' ; fi
  if [ x${DOCKER_ORGANISATION} == 'xnull' ] ; then DOCKER_ORGANISATION='' ; fi

  # Normalise resource group location to remove spaces and have lowercase
  RESOURCE_GROUP_LOCATION=`echo ${RESOURCE_GROUP_LOCATION//[[:blank:]]/} | tr '[:upper:]' '[:lower:]'`

  echo "--> Configuration read in:
    AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
    BINDERHUB_NAME: ${BINDERHUB_NAME}
    BINDERHUB_VERSION: ${BINDERHUB_VERSION}
    CONTACT_EMAIL: ${CONTACT_EMAIL}
    RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
    RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
    AKS_NODE_COUNT: ${AKS_NODE_COUNT}
    AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
    SP_APP_ID: ${SP_APP_ID}
    SP_APP_KEY: ${SP_APP_KEY}
    SP_TENANT_ID: ${SP_TENANT_ID}
    DOCKER_USERNAME: ${DOCKER_USERNAME}
    DOCKER_PASSWORD: ${DOCKER_PASSWORD}
    DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
    DOCKER_ORGANISATION: ${DOCKER_ORGANISATION}
    "

  # Check/get the user's Docker credentials
  if [ -z $DOCKER_USERNAME ] ; then
    if [ ! -z "$DOCKER_ORGANISATION" ]; then
      echo "--> Your docker ID must be a member of the ${DOCKER_ORGANISATION} organisation"
    fi
    read -p "DockerHub ID: " DOCKER_USERNAME
    read -sp "DockerHub password: " DOCKER_PASSWORD
    echo
  else
    if [ -z $DOCKER_PASSWORD ] ; then
      read -sp "DockerHub password for ${DOCKER_USERNAME}: " DOCKER_PASSWORD
      echo
    fi
  fi
fi

# Generate a valid name for the AKS cluster
AKS_NAME=`echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-' | cut -c 1-59`-AKS

# Azure login will be different depending on whether this script is running
# with or without service principal details supplied.
#
# If all the SP enironment is set, use that. Otherwise, fall back to an
# interactive login.


if [ -z $SP_APP_ID ] || [ -z $SP_APP_KEY ] || [ -z $SP_TENANT_ID ] ; then
  echo "--> Attempting to log in to Azure as a user"
  if ! az login -o none; then
      echo "--> Unable to connect to Azure" >&2
      exit 1
  else
      echo "--> Logged in to Azure"
  fi
else
  echo "--> Attempting to log in to Azure with service principal ${SP_APP_ID}"
  if ! az login --service-principal -u "${SP_APP_ID}" -p "${SP_APP_KEY}" -t "${SP_TENANT_ID}"; then
    echo "--> Unable to connect to Azure" >&2
    exit 1
  else
      echo "--> Logged in to Azure"
      # Use this service principal for AKS creation
      AKS_SP="--service-principal ${SP_APP_ID} --client-secret ${SP_APP_KEY}"
  fi
fi

# Activate chosen subscription
echo "--> Activating Azure subscription: ${AZURE_SUBSCRIPTION}"
az account set -s "$AZURE_SUBSCRIPTION"

# Create a new resource group if necessary
echo "--> Checking if resource group exists: ${RESOURCE_GROUP_NAME}"
if [[ $(az group exists --name $RESOURCE_GROUP_NAME) == false ]] ; then
  echo "--> Creating new resource group: ${RESOURCE_GROUP_NAME}"
  az group create -n $RESOURCE_GROUP_NAME --location $RESOURCE_GROUP_LOCATION -o table | tee rg-create.log
else
  echo "--> Resource group ${RESOURCE_GROUP_NAME} found."
fi

# Create an AKS cluster
echo "--> Creating AKS cluster; this may take a few minutes to complete
Resource Group: ${RESOURCE_GROUP_NAME}
Cluster name:   ${AKS_NAME}
Node count:     ${AKS_NODE_COUNT}
Node VM size:   ${AKS_NODE_VM_SIZE}"
az aks create -n $AKS_NAME -g $RESOURCE_GROUP_NAME --generate-ssh-keys --node-count $AKS_NODE_COUNT --node-vm-size $AKS_NODE_VM_SIZE -o table ${AKS_SP} | tee aks-create.log

# Get kubectl credentials from Azure
echo "--> Fetching kubectl credentials from Azure"
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME -o table | tee get-credentials.log

# Check nodes are ready
nodecount="$(kubectl get node | awk '{print $2}' | grep Ready | wc -l)"
while [[ ${nodecount} -ne ${AKS_NODE_COUNT} ]] ; do echo -n $(date) ; echo " : ${nodecount} of ${AKS_NODE_COUNT} nodes ready" ; sleep 15 ; nodecount="$(kubectl get node | awk '{print $2}' | grep Ready | wc -l)" ; done
echo
echo "--> Cluster node status:"
kubectl get node | tee kubectl-status.log
echo

# Setup ServiceAccount for tiller
echo "--> Setting up tiller service account"
kubectl --namespace kube-system create serviceaccount tiller | tee tiller-service-account.log

# Give the ServiceAccount full permissions to manage the cluster
echo "--> Giving the ServiceAccount full permissions to manage the cluster"
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller | tee cluster-role-bindings.log

# Initialise helm and tiller
echo "--> Initialising helm and tiller"
helm init --service-account tiller --wait | tee helm-init.log

# Secure tiller against attacks from within the cluster
echo "--> Securing tiller against attacks from within the cluster"
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]' | tee tiller-securing.log

# Waiting until tiller pod is ready
tillerStatus="$(kubectl get pods --namespace kube-system | grep ^tiller | awk '{print $3}')"
while [[ ! x${tillerStatus} == xRunning ]] ; do echo -n $(date) ; echo " : tiller pod status : ${tillerStatus} " ; sleep 30 ; tillerStatus="$(kubectl get pods --namespace kube-system | grep ^tiller | awk '{print $3}')" ; done
echo
echo "--> AKS system pods status:"
kubectl get pods --namespace kube-system | tee kubectl-get-pods.log
echo

# Check helm has been configured correctly
echo "--> Verify Client and Server are running the same version number:"
# Be error tolerant for this step
set +e
helmVersionAttempts=0
while ! helm version ; do
  ((helmVersionAttempts++))
  echo "--> helm version attempt ${helmVersionAttempts} of 3 failed"
  if (( helmVersionAttempts > 2 )) ; then
    echo "--> Please check helm versions manually later"
    break
  fi
  echo "--> Waiting 30 seconds before attempting helm version check again"
  sleep 30
done
# Revert to error-intolerance
set -e

# Create tokens for the secrets file:
apiToken=`openssl rand -hex 32`
secretToken=`openssl rand -hex 32`

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Get this script's path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub:
echo "--> Generating initial configuration file"
if [ -z "${DOCKER_ORGANISATION}" ] ; then
  sed -e "s/<docker-id>/$DOCKER_USERNAME/" \
  -e "s/<prefix>/$DOCKER_IMAGE_PREFIX/" \
  ./config-template.yaml > ./config.yaml
else
  sed -e "s/<docker-id>/$DOCKER_ORGANISATION/" \
  -e "s/<prefix>/$DOCKER_IMAGE_PREFIX/" \
  ./config-template.yaml > ./config.yaml
fi

echo "--> Generating initial secrets file"

sed -e "s/<apiToken>/$apiToken/" \
-e "s/<secretToken>/$secretToken/" \
-e "s/<docker-id>/$DOCKER_USERNAME/" \
-e "s/<password>/$DOCKER_PASSWORD/" \
./secret-template.yaml > ./secret.yaml

# Format name for kubernetes
HELM_BINDERHUB_NAME=$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//' )

echo "--> Installing Helm chart"
helm install jupyterhub/binderhub \
--version=$BINDERHUB_VERSION \
--name=$HELM_BINDERHUB_NAME \
--namespace=$HELM_BINDERHUB_NAME \
-f ./secret.yaml \
-f ./config.yaml \
--timeout=3600 | tee helm-chart-install.log

# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
echo "--> Retrieving JupyterHub IP"
JUPYTERHUB_IP=`kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1`
while [ "${JUPYTERHUB_IP}" = '<pending>' ] || [ "${JUPYTERHUB_IP}" = "" ]
do
    echo "Sleeping 30s before checking again"
    sleep 30
    JUPYTERHUB_IP=`kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1`
    echo "JupyterHub IP: ${JUPYTERHUB_IP}" | tee jupyterhub-ip.log
done

echo "--> Finalising configurations"
if [ -z "$DOCKER_ORGANISATION" ] ; then
  sed -e "s/<docker-id>/$DOCKER_USERNAME/" \
  -e "s/<prefix>/$DOCKER_IMAGE_PREFIX/" \
  -e "s/<jupyterhub-ip>/$JUPYTERHUB_IP/" \
  ./config-template.yaml > ./config.yaml
else
  sed -e "s/<docker-id>/$DOCKER_ORGANISATION/" \
  -e "s/<prefix>/$DOCKER_IMAGE_PREFIX/" \
  -e "s/<jupyterhub-ip>/$JUPYTERHUB_IP/" \
  ./config-template.yaml > ./config.yaml
fi

echo "--> Updating Helm chart"
helm upgrade $HELM_BINDERHUB_NAME jupyterhub/binderhub \
--version=$BINDERHUB_VERSION \
-f ./secret.yaml \
-f ./config.yaml | tee helm-upgrade.log

# Print Binder IP address
BINDER_IP=`kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1`
while [ "${BINDER_IP}" = '<pending>' ] || [ "${BINDER_IP}" = "" ]
do
    echo "Sleeping 30s before checking again"
    sleep 30
    BINDER_IP=`kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1`
    echo "Binder IP: ${BINDER_IP}" | tee binder-ip.log
done

if [ ! -z $BINDERHUB_CONTAINER_MODE ] ; then
  # Finally, save outputs to blob storage
  #
  # Create a storage account
  echo "--> Creating storage account"
  CONTAINER_NAME="${BINDERHUB_NAME}deploylogs"
  STORAGE_ACCOUNT_NAME="$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -20)$(openssl rand -hex 2)"
  az storage account create \
    --name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} \
    --sku Standard_LRS -o table | tee storage-create.log
  # Create a container
  echo "--> Creating storage container: ${CONTAINER_NAME}"
  az storage container create --account-name ${STORAGE_ACCOUNT_NAME} \
    --name ${CONTAINER_NAME} | tee container-create.log
  # Push the files
  echo "--> Pushing log files"
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "*.log"
  echo "--> Pushing yaml files"
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "*.yaml"
  echo "--> Getting and pushing ssh keys"
  cp ~/.ssh/id_rsa ./id_rsa_${BINDERHUB_NAME}
  cp ~/.ssh/id_rsa.pub ./id_rsa_${BINDERHUB_NAME}.pub
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "id*"
fi
