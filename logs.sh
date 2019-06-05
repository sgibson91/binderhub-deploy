#!/usr/bin/env bash

# Read config.json and get BinderHub name
configFile='config.json'
AKS_RESOURCE_GROUP=`jg -r '.azure .res_grp_name' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
AKS_NAME=`echo ${BINDERHUB_NAME}-AKS`

# Getting credentials for AKS cluster
echo "--> Getting credentials for AKS cluster"
az aks get-credentials -n $AKS_NAME -g $AKS_RESOURCE_GROUP

echo "--> Fetching JupyterHub logs"

# Get pod name of the JupyterHub
OUTPUT=`kubectl -n ${BINDERHUB_NAME} get pod | awk '{ print $1}' | tail -n 2`
OUTPUT=($OUTPUT)
HUB_POD=${OUTPUT[0]}

# Print the JupyterHub logs to the terminal
kubectl logs ${HUB_POD} -n ${BINDERHUB_NAME}
