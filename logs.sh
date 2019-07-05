#!/usr/bin/env bash

# Get this script's path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Read config.json and get BinderHub name
configFile="${DIR}/config.json"
AKS_RESOURCE_GROUP=`jg -r '.azure .res_grp_name' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
AKS_NAME=`echo ${BINDERHUB_NAME}-AKS`

# Getting credentials for AKS cluster
echo "--> Getting credentials for AKS cluster"
az aks get-credentials -n $AKS_NAME -g $AKS_RESOURCE_GROUP

echo "--> Fetching JupyterHub logs"

# Get pod name of the JupyterHub
HUB_POD=`kubectl get pods -n ${BINDERHUB_NAME} -o=jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep "^hub-"`

# Print the JupyterHub logs to the terminal
kubectl logs ${HUB_POD} -n ${BINDERHUB_NAME}
