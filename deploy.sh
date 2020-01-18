#!/bin/bash
# shellcheck disable=SC2086

# Exit immediately if a pipeline returns a non-zero status
set -eo pipefail

# Get this script's path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

if [[ -n $BINDERHUB_CONTAINER_MODE ]] ; then
  echo "--> Deployment operating in container mode"
  echo "--> Checking required environment variables"
  # Set out a list of required variables for this script
  REQUIREDVARS=" \
          AKS_NODE_COUNT \
          AKS_NODE_VM_SIZE \
          AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
          CONTAINER_REGISTRY \
          DOCKER_IMAGE_PREFIX \
          ENABLE_HTTPS \
          RESOURCE_GROUP_LOCATION \
          RESOURCE_GROUP_NAME \
          SP_APP_ID \
          SP_APP_KEY \
          SP_TENANT_ID \
          "
  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] ; then
      echo "--> ${required_var} must be set for container-based setup" >&2
      exit 1
    fi
  done

  if [ "$CONTAINER_REGISTRY" == 'dockerhub' ] ; then

    REQUIREDVARS=" \
            DOCKERHUB_USERNAME \
            DOCKERHUB_PASSWORD \
            "

    for required_var in $REQUIREDVARS ; do
      if [ -z "${!required_var}" ] ; then
        echo "--> ${required_var} must be set for container-based setup" >&2
        exit 1
      fi
    done

    # Check if DOCKERHUB_ORGANISATION is set to null. Return empty string if true.
    if [ x${DOCKERHUB_ORGANISATION} == 'xnull' ] ; then DOCKERHUB_ORGANISATION='' ; fi

  elif [ "$CONTAINER_REGISTRY" == 'azurecr' ] ; then

    REQUIREDVARS=" \
            REGISTRY_NAME \
            REGISTRY_SKU \
            "

    for required_var in $REQUIREDVARS ; do
      if [ -z "${!required_var}" ] ; then
        echo "--> ${required_var} must be set for container-based setup" >&2
        exit 1
      fi
    done

  else
    echo "--> Please provide a valid option for CONTAINER_REGISTRY."
    echo "    Options are 'dockerhub' or 'azurecr'."
    exit 1
  fi

  if [ "$ENABLE_HTTPS" == 'true' ] ; then

    REQUIREDVARS="\
      CERTMANAGER_VERSION \
      CONTACT_EMAIL \
      DOMAIN_NAME \
      "

    for required_var in $REQUIREDVARS ; do
      if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ] ; then
        echo "--> ${required_var} must be set for container-based setup" >&2
        exit 1
      fi
    done

    # Configure URL for Custom Resource Definitions
    STRIPPED_VERSION=$(echo "${CERTMANAGER_VERSION}" | tr -d 'v')
    SHORT_VERSION=${STRIPPED_VERSION%.*}
    CERTMANAGER_CRDS="https://raw.githubusercontent.com/jetstack/cert-manager/release-${SHORT_VERSION}/deploy/manifests/00-crds.yaml"

  else
    if [ x${CONTACT_EMAIL} == 'xnull' ] ; then CONTACT_EMAIL='' ; fi
    if [ x${DOMAIN_NAME} == 'xnull' ] ; then DOMAIN_NAME='' ; fi
    if [ x${CERTMANAGER_VERSION} == 'xnull' ] ; then CERTMANAGER_VERSION='' ; fi
  fi

  # Azure blue-button prepends '/subscription/' to AZURE_SUBSCRIPTION
  AZURE_SUBSCRIPTION=$(echo $AZURE_SUBSCRIPTION | sed -r "s/^\/subscriptions\///")

  echo "--> Configuration parsed from blue button:
      AKS_NODE_COUNT: ${AKS_NODE_COUNT}
      AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
      AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
      BINDERHUB_NAME: ${BINDERHUB_NAME}
      BINDERHUB_VERSION: ${BINDERHUB_VERSION}
      CERTMANAGER_VERSION: ${CERTMANAGER_VERSION}
      CONTACT_EMAIL: ${CONTACT_EMAIL}
      CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
      DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
      DOCKERHUB_ORGANISATION: ${DOCKERHUB_ORGANISATION}
      DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}
      DOMAIN_NAME: ${DOMAIN_NAME}
      ENABLE_HTTPS: ${ENABLE_HTTPS}
      REGISTRY_NAME: ${REGISTRY_NAME}
      REGISTRY_SKU: ${REGISTRY_SKU}
      RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
      RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
      SP_APP_ID: ${SP_APP_ID}
      SP_TENANT_ID: ${SP_TENANT_ID}
      " | tee read-config.log

else

  # Read in config file and assign variables for the non-container case
  configFile="${DIR}/config.json"

  echo "--> Reading configuration from ${configFile}"

  AKS_NODE_COUNT=$(jq -r '.azure .node_count' ${configFile})
  AKS_NODE_VM_SIZE=$(jq -r '.azure .vm_size' ${configFile})
  AZURE_SUBSCRIPTION=$(jq -r '.azure .subscription' ${configFile})
  BINDERHUB_NAME=$(jq -r '.binderhub .name' ${configFile})
  BINDERHUB_VERSION=$(jq -r '.binderhub .version' ${configFile})
  CONTAINER_REGISTRY=$(jq -r '.container_registry' ${configFile})
  DOCKER_IMAGE_PREFIX=$(jq -r '.binderhub .image_prefix' ${configFile})
  ENABLE_HTTPS=$(jq -r '.enable_https' ${configFile})
  RESOURCE_GROUP_LOCATION=$(jq -r '.azure .location' ${configFile})
  RESOURCE_GROUP_NAME=$(jq -r '.azure .res_grp_name' ${configFile})
  SP_APP_ID=$(jq -r '.azure .sp_app_id' ${configFile})
  SP_APP_KEY=$(jq -r '.azure .sp_app_key' ${configFile})
  SP_TENANT_ID=$(jq -r '.azure .sp_tenant_id' ${configFile})

  # Check that the variables are all set non-zero, non-null
  REQUIREDVARS=" \
          AKS_NODE_COUNT \
          AKS_NODE_VM_SIZE \
          AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
          CONTAINER_REGISTRY \
          DOCKER_IMAGE_PREFIX \
          ENABLE_HTTPS \
          RESOURCE_GROUP_LOCATION \
          RESOURCE_GROUP_NAME \
          "

  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ] ; then
      echo "--> ${required_var} must be set for deployment" >&2
      exit 1
    fi
  done

  # Check if any optional variables are set null; if so, reset them to a
  # zero-length string for later checks. If they failed to read at all,
  # possibly due to an invalid json file, they will be returned as a
  # zero-length string -- this is attempting to make the 'not set'
  # value the same in either case
  if [ x${SP_APP_ID} == 'xnull' ] ; then SP_APP_ID='' ; fi
  if [ x${SP_APP_KEY} == 'xnull' ] ; then SP_APP_KEY='' ; fi
  if [ x${SP_TENANT_ID} == 'xnull' ] ; then SP_TENANT_ID='' ; fi

  # Test value of CONTAINER_REGISTRY. Must be either "dockerhub" or "azurecr"
  if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ] ; then
    echo "--> Getting DockerHub requirements"

    # Read Docker credentials from config file
    DOCKERHUB_ORGANISATION=$(jq -r '.docker .org' ${configFile})
    DOCKERHUB_PASSWORD=$(jq -r '.docker .password' ${configFile})
    DOCKERHUB_USERNAME=$(jq -r '.docker .username' ${configFile})

    # Check that Docker Hub credentials have been set
    if [ x${DOCKERHUB_ORGANISATION} == 'xnull' ] ; then DOCKERHUB_ORGANISATION='' ; fi
    if [ x${DOCKERHUB_PASSWORD} == 'xnull' ] ; then DOCKERHUB_PASSWORD='' ; fi
    if [ x${DOCKERHUB_USERNAME} == 'xnull' ] ; then DOCKERHUB_USERNAME='' ; fi

    # Check/get the user's Docker Hub credentials
    if [ -z $DOCKERHUB_USERNAME ] ; then
      if [ -n "$DOCKERHUB_ORGANISATION" ] ; then
        echo "--> Your Docker ID must be a member of the ${DOCKERHUB_ORGANISATION} organisation"
      fi
      read -rp "DockerHub ID: " DOCKERHUB_USERNAME
      read -rsp "DockerHub password: " DOCKERHUB_PASSWORD
      echo
    else
      if [ -z $DOCKERHUB_PASSWORD ] ; then
        read -rsp "Docker Hub password for ${DOCKERHUB_USERNAME}: " DOCKERHUB_PASSWORD
        echo
      fi
    fi

  elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ] ; then
    echo "--> Getting configuration for Azure Container Registry"

    # Read in ACR configuration
    REGISTRY_NAME=$(jq -r '.acr .registry_name' ${configFile})
    REGISTRY_SKU=$(jq -r '.acr .sku' ${configFile})

    # Checking required variables
    REQUIREDVARS=" \
        REGISTRY_NAME \
        REGISTRY_SKU \
        SP_APP_ID \
        SP_APP_KEY \
        "

    for required_var in $REQUIREDVARS ; do
      if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ] ; then
        echo "--> ${required_var} must be set for deployment" >&2
        exit 1
      fi
    done

    # ACR name must be alphanumeric only and 50 characters or less
    REGISTRY_NAME=$(echo ${REGISTRY_NAME} | tr -cd '[:alnum:]' | cut -c -50)

  else
    echo "--> Please provide a valid option for CONTAINER_REGISTRY."
    echo "    Options are: 'dockerhub' or 'azurecr'."
  fi

  if [ "$ENABLE_HTTPS" == 'true' ] ; then

    # Read in cert-manager config
    CERTMANAGER_VERSION=$(jq -r '.cert_manager .version' ${configFile})
    CONTACT_EMAIL=$(jq -r '.cert_manager .contact_email' ${configFile})
    DOMAIN_NAME=$(jq -r '.cert_manager .domain_name' ${configFile})

    # Checking required variables
    REQUIREDVARS="\
      CERTMANAGER_VERSION \
      CONTACT_EMAIL \
      DOMAIN_NAME \
      "

    for required_var in $REQUIREDVARS ; do
      if [ -z "${!required_var}" ] || [ x${!required_var} == 'xnull' ] ; then
        echo "--> ${required_var} must be set for deployment" >&2
        exit 1
      fi
    done

    # Configure URL for Custom Resource Definitions
    STRIPPED_VERSION=$(echo "${CERTMANAGER_VERSION}" | tr -d 'v')
    SHORT_VERSION=${STRIPPED_VERSION%.*}
    CERTMANAGER_CRDS="https://raw.githubusercontent.com/jetstack/cert-manager/release-${SHORT_VERSION}/deploy/manifests/00-crds.yaml"

  else
    if [ x${CONTACT_EMAIL} == 'xnull' ] ; then CONTACT_EMAIL='' ; fi
    if [ x${DOMAIN_NAME} == 'xnull' ] ; then DOMAIN_NAME='' ; fi
    if [ x${CERTMANAGER_VERSION} == 'xnull' ] ; then CERTMANAGER_VERSION='' ; fi
  fi

  echo "--> Configuration read in:
      AKS_NODE_COUNT: ${AKS_NODE_COUNT}
      AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
      AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
      BINDERHUB_NAME: ${BINDERHUB_NAME}
      BINDERHUB_VERSION: ${BINDERHUB_VERSION}
      CERTMANAGER_VERSION: ${CERTMANAGER_VERSION}
      CONTACT_EMAIL: ${CONTACT_EMAIL}
      CONTAINER_REGISTRY: ${CONTAINER_REGISTRY}
      DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
      DOCKERHUB_ORGANISATION: ${DOCKERHUB_ORGANISATION}
      DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}
      DOMAIN_NAME: ${DOMAIN_NAME}
      ENABLE_HTTPS: ${ENABLE_HTTPS}
      REGISTRY_NAME: ${REGISTRY_NAME}
      REGISTRY_SKU: ${REGISTRY_SKU}
      RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
      RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
      SP_APP_ID: ${SP_APP_ID}
      SP_TENANT_ID: ${SP_TENANT_ID}
      " | tee read-config.log

fi

set -eo pipefail

# Normalise resource group location to remove spaces and have lowercase
RESOURCE_GROUP_LOCATION=$(echo ${RESOURCE_GROUP_LOCATION//[[:blank::]]/} | tr '[:upper:]' '[:lower:]')

# Generate a valid name for the AKS cluster
AKS_NAME=$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-' | cut -c 1-59)-AKS

# Format BinderHub name for Kubernetes
HELM_BINDERHUB_NAME=$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//' )

# Azure login will be different depending on whether this script is running
# with or without service principal details supplied.
#
# If all the SP environments are set, use those. Otherwise, fall back to an
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
  echo "--> Attempting to log in to Azure with provided Service Principal"
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
  echo "--> Resource group ${RESOURCE_GROUP_NAME} found"
fi

# Create a Virtual Network to deploy the k8s cluster into
echo "--> Creating a Virtual Network and subnet"
az network vnet create \
    -g ${RESOURCE_GROUP_NAME} \
    -n ${BINDERHUB_NAME}-vnet \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name ${BINDERHUB_NAME}-subnet \
    --subnet-prefix 10.240.0.0/16 | tee create-vnet.log
echo "--> Retrieving the Virtual Network application ID"
VNET_ID=$(az network vnet show -g ${RESOURCE_GROUP_NAME} -n ${BINDERHUB_NAME}-vnet --query id -o tsv)
echo "--> Retrieving the subnet application ID"
SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP_NAME} --vnet-name ${BINDERHUB_NAME}-vnet -n ${BINDERHUB_NAME}-subnet --query id -o tsv)

# If no Service Principal is provided, create one
if [ -z "${SP_APP_ID}" ] && [ -z "${SP_APP_KEY}" ] ; then
    SP_NAME='binderhub-sp'
    echo "--> Creating Service Principal ${SP_NAME}"
    SP_APP_KEY=$(az ad sp create-for-rbac -n http://${SP_NAME} --skip-assignment --query password -o tsv)
    SP_APP_ID=$(az ad sp show --id http://${SP_NAME} --query appId -o tsv)
    echo "Waiting for Service Principal to propagate"
    sleep 15
    AKS_SP="--service-principal ${SP_APP_ID} --client-secret ${SP_APP_KEY}"
fi

# Assign Contributor role to Service Principal
az role assignment create --assignee ${SP_APP_ID} --scope ${VNET_ID} --role Contributor

# If Azure container registry is required, create an ACR and give Service Principal AcrPush role.
if [ x${CONTAINER_REGISTRY} == 'xazurecr' ] ; then
  echo "--> Checking ACR name availability"
  REGISTRY_NAME_AVAIL=$(az acr check-name -n ${REGISTRY_NAME} --query nameAvailable -o tsv)
  while [ ${REGISTRY_NAME_AVAIL} == false ]
  do
    echo "--> Name ${REGISTRY_NAME} not available. Appending 4 random characters."
    REGISTRY_NAME="$(echo ${REGISTRY_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -50)$(openssl rand -hex 2)"
    echo "--> New name: ${REGISTRY_NAME}"
    REGISTRY_NAME_AVAIL=$(az acr check-name -n ${REGISTRY_NAME} --query nameAvailable -o tsv)
  done
  echo "--> Name available"

  echo "--> Creating ACR"
  az acr create -n $REGISTRY_NAME -g $RESOURCE_GROUP_NAME --sku $REGISTRY_SKU -o table | tee acr-create.log

  # Populating some variables
  ACR_LOGIN_SERVER=$(az acr list -g ${RESOURCE_GROUP_NAME} --query '[].{acrLoginServer:loginServer}' -o tsv)
  ACR_ID=$(az acr show -n ${REGISTRY_NAME} -g ${RESOURCE_GROUP_NAME} --query 'id' -o tsv)

  # Assigning AcrPush role to Service Principal using AcrPush's specific object-ID
  echo "--> Assigning AcrPush role to Service Principal"
  az role assignment create --assignee ${SP_APP_ID} --role 8311e382-0749-4cb8-b61a-304f252e45ec --scope $ACR_ID -o table | tee role-assignment.log

  # Reassign IMAGE_PREFIX to conform with BinderHub's expectation:
  # <container-registry>/<project-id>/<prefix>-name:tag
  IMAGE_PREFIX=${BINDERHUB_NAME}/${IMAGE_PREFIX}
fi

# Create an AKS cluster
echo "--> Creating AKS cluster; this may take a few minutes to complete
Resource Group: ${RESOURCE_GROUP_NAME}
Cluster name:   ${AKS_NAME}
Node count:     ${AKS_NODE_COUNT}
Node VM size:   ${AKS_NODE_VM_SIZE}"
az aks create \
    -n $AKS_NAME \
    -g $RESOURCE_GROUP_NAME \
    --generate-ssh-keys \
    --node-count $AKS_NODE_COUNT \
    --node-vm-size $AKS_NODE_VM_SIZE \
    --dns-service-ip 10.0.0.10 \
    --docker-bridge-address 172.17.0.1/16 \
    --network-plugin azure \
    --network-policy azure \
    --service-cidr 10.0.0.0/16 \
    --vnet-subnet-id $SUBNET_ID \
    -o table ${AKS_SP} \
    | tee aks-create.log

# Get kubectl credentials from Azure
echo "--> Fetching kubectl credentials from Azure"
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME --overwrite-existing | tee get-credentials.log

# Check nodes are ready
nodecount="$(kubectl get node | awk '{print $2}' | grep -c Ready)"
while [[ ${nodecount} -ne ${AKS_NODE_COUNT} ]] ; do echo -n "$(date)" ; echo " : ${nodecount} of ${AKS_NODE_COUNT} nodes ready" ; sleep 15 ; nodecount="$(kubectl get node | awk '{print $2}' | grep -c Ready)" ; done
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
while [[ ! x${tillerStatus} == xRunning ]] ; do echo -n "$(date)" ; echo " : tiller pod status : ${tillerStatus} " ; sleep 30 ; tillerStatus="$(kubectl get pods --namespace kube-system | grep ^tiller | awk '{print $3}')" ; done
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
    echo "--> Please check helm versions manually later. Run 'helm init --upgrade' if they do not match."
    break
  fi
  echo "--> Waiting 30 seconds before attempting helm version check again"
  sleep 30
done
# Revert to error-intolerance
set -eo pipefail

# Create tokens for the secrets file:
apiToken=$(openssl rand -hex 32)
secretToken=$(openssl rand -hex 32)

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# If HTTPS is enabled, get cert-manager helm chart and install it into the
# cert-manager namespace
if [ "$ENABLE_HTTPS" == 'true' ] ; then
  echo "--> Add cert-manager helm repo"
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  kubectl apply --validate=false -f ${CERTMANAGER_CRDS}

  echo "--> Install cert-manager helm repo"
  helm install jetstack/cert-manager \
  --name cert-manager \
  --namespace cert-manager \
  --version ${CERTMANAGER_VERSION} \
  --timeout=3600 \
  --wait | tee cert-manager-chart-install.log

  echo "--> cert-manager pods status:"
  kubectl get pods --namespace cert-manager | tee cert-manager-get-pods.log

  # Create a ClusterIssuer to test deployment
  echo "--> Testing cert-manager webhooks"
  kubectl apply -f ${DIR}/templates/test-resources.yaml
  sleep 30
  kubectl describe certificate -n cert-manager-test | tee cert-manager-test.log

  # Clean up resources
  kubectl delete -f ${DIR}/templates/test-resources.yaml

  # Parse info to cluster issuer
  echo "--> Writing ClusterIssuer config"
  sed -e "s/<namespace>/${HELM_BINDERHUB_NAME}/g" \
      -e "s/<contact_email>/${CONTACT_EMAIL}/g" \
      ${DIR}/templates/cluster-issuer-template.yaml > ${DIR}/cluster-issuer.yaml

  BINDER_HOST="binder.${DOMAIN_NAME}"
  HUB_HOST="hub.${DOMAIN_NAME}"
  BINDER_SECRET="${HELM_BINDERHUB_NAME}-binder-secret"
  HUB_SECRET="${HELM_BINDERHUB_NAME}-hub-secret"

  # Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub.
  if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ] ; then

    echo "--> Generating initial configuration file"
    if [ -z "${DOCKERHUB_ORGANISATION}" ] ; then
      sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
      -e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
      -e "s/<jupyterhub-ip>/${HUB_HOST}/" \
      -e "s/<cluster-issuer>/letsencrypt-staging/g" \
      -e "s/<binder-host>/${BINDER_HOST}/g" \
      -e "s/<binder-secret-name>/${BINDER_SECRET}/" \
      -e "s/<hub-host>/${HUB_HOST}/g" \
      -e "s/<hub-secret-name>/${HUB_SECRET}/" \
      ${DIR}/templates/https-config-template.yaml > ${DIR}/config.yaml
    else
      sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
      -e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
      -e "s/<jupyterhub-ip>/${HUB_HOST}/" \
      -e "s/<cluster-issuer>/letsencrypt-staging/g" \
      -e "s/<binder-host>/${BINDER_HOST}/g" \
      -e "s/<binder-secret-name>/${BINDER_SECRET}/" \
      -e "s/<hub-host>/${HUB_HOST}/g" \
      -e "s/<hub-secret-name>/${HUB_SECRET}/" \
      ${DIR}/templates/https-config-template.yaml > ${DIR}/config.yaml
    fi

    echo "--> Generating initial secrets file"
    sed -e "s/<apiToken>/${apiToken}/" \
    -e "s/<secretToken>/${secretToken}/" \
    -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
    -e "s/<password>/${DOCKERHUB_PASSWORD}/" \
    ${DIR}/templates/secret-template.yaml > ${DIR}/secret.yaml
  fi
fi

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub.
if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ] ; then

  echo "--> Generating initial configuration file"
  if [ -z "${DOCKERHUB_ORGANISATION}" ] ; then
    sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
    -e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
    ${DIR}/templates/config-template.yaml > ${DIR}/config.yaml
  else
    sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
    -e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
    ${DIR}/templates/config-template.yaml > ${DIR}/config.yaml
  fi

  echo "--> Generating initial secrets file"
  sed -e "s/<apiToken>/${apiToken}/" \
  -e "s/<secretToken>/${secretToken}/" \
  -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
  -e "s/<password>/${DOCKERHUB_PASSWORD}/" \
  ${DIR}/templates/secret-template.yaml > ${DIR}/secret.yaml

elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ] ; then

  echo "--> Generating initial configuration file"
  sed -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@g" \
  -e "s@<prefix>@${DOCKER_IMAGE_PREFIX}@" \
  ${DIR}/templates/acr-config-template.yaml > ${DIR}/config.yaml

  echo "--> Generating initial secrets file"
  sed -e "s/<apiToken>/${apiToken}/" \
  -e "s/<secretToken>/${secretToken}/" \
  -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@" \
  -e "s/<username>/${SP_APP_ID}/" \
  -e "s/<password>/${SP_APP_KEY}/" \
${DIR}/templates/acr-secret-template.yaml > ${DIR}/secret.yaml
fi

echo "--> Installing Helm chart"
helm install jupyterhub/binderhub \
--version=$BINDERHUB_VERSION \
--name=$HELM_BINDERHUB_NAME \
--namespace=$HELM_BINDERHUB_NAME \
-f ${DIR}/secret.yaml \
-f ${DIR}/config.yaml \
--timeout=3600 \
--wait | tee binderhub-chart-install.log

# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
echo "--> Retrieving JupyterHub IP"
# shellcheck disable=SC2030 disable=SC2036
JUPYTERHUB_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1) | tee jupyterhub-ip.log
# shellcheck disable=SC2031
while [ "${JUPYTERHUB_IP}" = '<pending>' ] || [ "${JUPYTERHUB_IP}" = "" ]
do
    echo "Sleeping 30s before checking again"
    sleep 30
    JUPYTERHUB_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1)
    echo "JupyterHub IP: ${JUPYTERHUB_IP}" | tee jupyterhub-ip.log
done

if [ x${CONTAINER_REGISTRY} == 'xdockerhub' ] ; then

  echo "--> Finalising configurations"
  if [ -z "$DOCKERHUB_ORGANISATION" ] ; then
    sed -e "s/<docker-id>/${DOCKERHUB_USERNAME}/" \
    -e "s/<prefix>/${DOCKER_IMAGE_PREFIX}/" \
    -e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
    ${DIR}/templates/config-template.yaml > ${DIR}/config.yaml
  else
    sed -e "s/<docker-id>/${DOCKERHUB_ORGANISATION}/" \
    -e "s/<prefix>/${DOCKERHUB_IMAGE_PREFIX}/" \
    -e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
    ${DIR}/templates/config-template.yaml > ${DIR}/config.yaml
  fi

elif [ x${CONTAINER_REGISTRY} == 'xazurecr' ] ; then

  echo "--> Finalising configurations"
  sed -e "s@<acr-login-server>@${ACR_LOGIN_SERVER}@g" \
  -e "s@<prefix>@${DOCKER_IMAGE_PREFIX}@" \
  -e "s/<jupyterhub-ip>/${JUPYTERHUB_IP}/" \
  ${DIR}/templates/acr-config-template.yaml > ${DIR}/config.yaml

fi

echo "--> Updating Helm chart"
helm upgrade $HELM_BINDERHUB_NAME jupyterhub/binderhub \
--version=$BINDERHUB_VERSION \
-f ${DIR}/secret.yaml \
-f ${DIR}/config.yaml \
--wait | tee helm-upgrade.log

# Print Binder IP address
echo "--> Retrieving Binder IP"
BINDER_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1)
echo "Binder IP: ${BINDER_IP}" | tee binder-ip.log
while [ "${BINDER_IP}" = '<pending>' ] || [ "${BINDER_IP}" = "" ]
do
    echo "Sleeping 30s before checking again"
    sleep 30
    BINDER_IP=$(kubectl --namespace=$HELM_BINDERHUB_NAME get svc binder | awk '{ print $4}' | tail -n 1)
    echo "Binder IP: ${BINDER_IP}" | tee binder-ip.log
done

if [[ -n $BINDERHUB_CONTAINER_MODE ]] ; then
  # Finally, save outputs to blob storage
  #
  # Create a storage account
  echo "--> Creating storage account"
  CONTAINER_NAME="$(echo ${BINDERHUB_NAME}deploylogs | tr '[:upper:]' '[:lower:]')"
  STORAGE_ACCOUNT_NAME="$(echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c -20)$(openssl rand -hex 2)"
  az storage account create \
    --name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} \
    --sku Standard_LRS -o table | tee storage-create.log
  # Create a container
  echo "--> Creating storage container: ${CONTAINER_NAME}"
  az storage container create --account-name ${STORAGE_ACCOUNT_NAME} \
    --name ${CONTAINER_NAME} -o table | tee container-create.log
  # Push the files
  echo "--> Pushing log files"
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "*.log" -o table
  echo "--> Pushing yaml files"
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "*.yaml" -o table
  echo "--> Getting and pushing ssh keys"
  cp ~/.ssh/id_rsa ${DIR}/id_rsa_${BINDERHUB_NAME}
  cp ~/.ssh/id_rsa.pub ${DIR}/id_rsa_${BINDERHUB_NAME}.pub
  az storage blob upload-batch --account-name ${STORAGE_ACCOUNT_NAME} \
    --destination ${CONTAINER_NAME} --source "." \
    --pattern "id*" -o table
fi
