#!/usr/bin/env bash

# Read in config.json and get variables
configFile='config.json'
binderhubname=`jq -r '.binderhub .name' ${configFile}`

# Get IP addresses of both the JupyterHub and BinderHub
echo "Jupyterhub IP: " `kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
echo "Binderhub IP: " `kubectl --namespace=$binderhubname get svc binder | awk '{ print $4}' | tail -n 1`
