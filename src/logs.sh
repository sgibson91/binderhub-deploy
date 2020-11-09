#!/bin/bash

# Get this script's path
DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# Read config.json and get BinderHub name
configFile="${DIR}/config.json"
AKS_RESOURCE_GROUP=$(jq -r '.azure .res_grp_name' "${configFile}")
BINDERHUB_NAME=$(jq -r '.binderhub .name' "${configFile}")
AKS_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-' | cut -c 1-59)-AKS
HELM_BINDERHUB_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//')

# Getting credentials for AKS cluster
echo "--> Getting credentials for AKS cluster"
az aks get-credentials -n "${AKS_NAME}" -g "${AKS_RESOURCE_GROUP}"

echo "--> Fetching JupyterHub logs"

# Get pod name of the JupyterHub
HUB_POD=$(kubectl get pods -n "${HELM_BINDERHUB_NAME}" -o=jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep "^hub-")

# Print the JupyterHub logs to the terminal
kubectl logs "${HUB_POD}" -n "${HELM_BINDERHUB_NAME}"
