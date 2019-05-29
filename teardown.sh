#!/usr/bin/env bash

# Read in config.json
configFile='config.json'
binderhubname=`jq -r '.binderhub .name' ${configFile}`
res_grp_name=`jq -r '.azure .res_grp_name' ${configFile}`

# Purge the Helm release and delete the Kubernetes namespace
echo "--> Purging the helm chart"
helm delete $binderhubname --purge

echo "--> Deleting the namespace: $binderhubname"
kubectl delete namespace $binderhubname

# Delete Azure Resource Group
echo "--> Deleting the resource group: $res_grp_name"
az group delete -n $res_grp_name

echo "--> Deleting the resource group: NetworkWatcherRG"
az group delete -n NetworkWatcherRG

echo "Double check resources are down:"
echo "               https://portal.azure.com/#home -> Click on Resource Groups"
echo "Check your DockerHub registry:"
echo "               https://hub.docker.com/"
echo "For more info: https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#delete-the-helm-release"
echo "               https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#microsoft-azure-aks"
