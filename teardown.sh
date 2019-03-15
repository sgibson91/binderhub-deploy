#!/bin/bash

# Read in config.json
outputs=`python read_config.py`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)

res_grp_name=${vararray[1]}
binderhubname=${vararray[6]}

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
