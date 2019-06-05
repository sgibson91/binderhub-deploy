#!/usr/bin/env bash

# Read in config.json and get variables
configFile='config.json'
AKS_RESOURCE_GROUP=`jq -r '.azure .res_grp_name' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
AKS_NAME=`echo ${BINDERHUB_NAME}-AKS`

# Get AKS cluster credentials
echo "--> Get credentials for AKS cluster"
az aks get-credentials -n $AKS_NAME -g $AKS_RESOURCE_GROUP

# Print pods
echo "--> Printing pods"
kubectl get pods -n ${BINDERHUB_NAME}
echo

# Get IP addresses of both the JupyterHub and BinderHub
echo "Jupyterhub IP: " `kubectl --namespace=${BINDERHUB_NAME} get svc proxy-public | awk '{ print $4}' | tail -n 1`
echo "Binderhub IP: " `kubectl --namespace=${BINDERHUB_NAME} get svc binder | awk '{ print $4}' | tail -n 1`
