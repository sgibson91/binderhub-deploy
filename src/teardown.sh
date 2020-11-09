#!/bin/bash

# Get this script's path
DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# Read in config.json
configFile="${DIR}"/config.json
BINDERHUB_NAME=$(jq -r '.binderhub .name' "${configFile}")
RESOURCE_GROUP=$(jq -r '.azure .res_grp_name' "${configFile}")
ENABLE_HTTPS=$(jq -r '.enable_https' "${configFile}")

AKS_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-' | cut -c 1-59)-AKS
AKS_USERNAME="users.clusterUser_${RESOURCE_GROUP}_${AKS_NAME}"
HELM_BINDERHUB_NAME=$(echo "${BINDERHUB_NAME}" | tr -cd '[:alnum:]-.' | tr '[:upper:]' '[:lower:]' | sed -E -e 's/^([.-]+)//' -e 's/([.-]+)$//')

# If CRDs were installed, delete them
if [[ -n $ENABLE_HTTPS ]]; then
	echo "--> Deleting Custom Resource Definitions"
	kubectl delete crds --all
	kubectl delete apiservices v1beta1.webhook.cert-manager.io
fi

# Purge the Helm release and delete the Kubernetes namespace
echo "--> Purging the helm chart: ${HELM_BINDERHUB_NAME}"
helm delete "${HELM_BINDERHUB_NAME}" --timeout 10m0s

echo "--> Deleting the namespace: ${HELM_BINDERHUB_NAME}"
kubectl delete namespace "${HELM_BINDERHUB_NAME}"

echo "--> Purging the kubectl config file"
kubectl config unset current-context
kubectl config delete-cluster "${AKS_NAME}"
kubectl config delete-context "${AKS_NAME}"
kubectl config unset "${AKS_USERNAME}"

# Delete Azure Resource Group
echo "--> Deleting the resource group: ${RESOURCE_GROUP}"
az group delete -n "${RESOURCE_GROUP}" --yes --no-wait

echo "--> Deleting the resource group: NetworkWatcherRG"
az group delete -n NetworkWatcherRG --yes --no-wait

echo "NOTE: It is a long running process to delete a resource group."
echo "      The groups are probably still undergoing deletion presently."
echo "Double check resources are down:"
echo "               https://portal.azure.com/#home -> Click on Resource Groups"
echo "Check your DockerHub registry:"
echo "               https://hub.docker.com/"
echo "For more info: https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#delete-the-helm-release"
echo "               https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#microsoft-azure-aks"
