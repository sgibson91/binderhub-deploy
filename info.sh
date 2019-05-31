#!/usr/bin/env bash

# Read in config.json and get variables
configFile='config.json'
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`

# Print pods
echo "--> Printing pods"
kubectl get pods -n ${BINDERHUB_NAME}
echo

# Get IP addresses of both the JupyterHub and BinderHub
echo "Jupyterhub IP: " `kubectl --namespace=${BINDERHUB_NAME} get svc proxy-public | awk '{ print $4}' | tail -n 1`
echo "Binderhub IP: " `kubectl --namespace=${BINDERHUB_NAME} get svc binder | awk '{ print $4}' | tail -n 1`
