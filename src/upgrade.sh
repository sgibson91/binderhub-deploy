#!/bin/bash

# Get this script's path
DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# Read in config.json and get variables
echo "--> Reading in config.json"
configFile="${DIR}/config.json"
AKS_RESOURCE_GROUP=$(jq -r '.azure .res_grp_name' "${configFile}")
BINDERHUB_NAME=$(jq -r '.binderhub .name' "${configFile}")
BINDERHUB_VERSION=$(jq -r '.binderhub .version' "${configFile}")

# Generate a valid name for the AKS cluster
AKS_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-' | cut -c 1-59)-AKS

# Format BinderHub name for Kubernetes
HELM_BINDERHUB_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//')

# Get cluster credentials
echo "--> Getting credentials for AKS cluster"
az aks get-credentials -n "${AKS_NAME}" -g "${AKS_RESOURCE_GROUP}"

# Pull and update helm chart repo
echo "--> Updating helm chart repo"
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Upgrade helm chart
echo "--> Upgrading ${HELM_BINDERHUB_NAME}'s helm chart with version ${BINDERHUB_VERSION}"
helm upgrade "${HELM_BINDERHUB_NAME}" jupyterhub/binderhub \
	--namespace "${HELM_BINDERHUB_NAME}" \
	--version="${BINDERHUB_VERSION}" \
	-f "${DIR}/secret.yaml" \
	-f "${DIR}/config.yaml" \
	--cleanup-on-fail \
	--timeout 10m0s \
	--wait

# Print Kubernetes pods
echo "--> Getting pods"
kubectl get pods -n "${HELM_BINDERHUB_NAME}"
