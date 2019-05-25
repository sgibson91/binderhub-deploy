#!/usr/bin/env bash

# Read in config.json and get variables
echo "--> Reading in config.json"
configFile='config.json'
binderhubname=`jq -r '.binderhub .name' ${configFile}`
binderhubversion=`jq -r '.binderhub .version' ${configFile}`

# Pull and update helm chart repo
echo "--> Updating helm chart repo"
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Upgrade helm chart
echo "--> Upgrading ${binderhubname}'s helm chart with version ${binderhubversion}"
helm upgrade ${binderhubname} jupyterhub/binderhub --version=${binderhubversion} -f secret.yaml -f config.yaml

# Print Kubernetes pods
echo "--> Getting pods"
kubectl get pods -n ${binderhubname}
