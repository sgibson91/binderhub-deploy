#!/usr/bin/env bash

# Read in config.json and get variables
echo "--> Reading in config.json"
configFile='config.json'
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
HELM_BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`

# Pull and update helm chart repo
echo "--> Updating helm chart repo"
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Upgrade helm chart
echo "--> Upgrading ${BINDERHUB_NAME}'s helm chart with version ${HELM_BINDERHUB_VERSION}"
helm upgrade ${BINDERHUB_NAME} jupyterhub/binderhub \
--version=${HELM_BINDERHUB_VERSION} \
-f secret.yaml \
-f config.yaml

# Print Kubernetes pods
echo "--> Getting pods"
kubectl get pods -n ${BINDERHUB_NAME}
