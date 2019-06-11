#!/usr/bin/env bash

# Get this script's path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Read in config.json and get variables
echo "--> Reading in config.json"
configFile="${DIR}/config.json"
AKS_RESOURCE_GROUP=`jq -r '.azure .res_grp_name' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`
AKS_NAME=`echo ${BINDERHUB_NAME}-AKS`

# Get cluster credentials
echo "--> Getting credentials for AKS cluster"
az aks get-credentials -n $AKS_NAME -g $AKS_RESOURCE_GROUP

# Initialise helm
echo "--> Initialising helm"
helm init --client-only

# Pull and update helm chart repo
echo "--> Updating helm chart repo"
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Upgrade helm chart
echo "--> Upgrading ${BINDERHUB_NAME}'s helm chart with version ${BINDERHUB_VERSION}"
helm upgrade $BINDERHUB_NAME jupyterhub/binderhub \
--version=$BINDERHUB_VERSION \
-f ${DIR}/secret.yaml \
-f ${DIR}/config.yaml

# Print Kubernetes pods
echo "--> Getting pods"
kubectl get pods -n $BINDERHUB_NAME
