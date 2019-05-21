#!/usr/bin/env bash

# Read in config.json
configFile='config.json'
binderhubname=`jq -r '.binderhub .name' ${configFile}`
res_grp_name=`jq -r '.azure .res_grp_name' ${configFile}`

# Delete the Helm release and purge the Kubernetes namespace
helm delete $binderhubname --purge
kubectl delete namespace $binderhubname

# Delete Azure Resource Group
az group delete --name $res_grp_name

echo "Double check resources are down:"
echo "               https://portal.azure.com/#home -> Click on Resource Groups"
echo "Check your DockerHub registry:"
echo "               https://hub.docker.com/"
echo "For more info: https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#delete-the-helm-release"
echo "               https://zero-to-jupyterhub.readthedocs.io/en/latest/turn-off.html#microsoft-azure-aks"
