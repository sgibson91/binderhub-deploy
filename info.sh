#!/bin/bash

# Read in config.json and get variables
outputs=`python read_config.py`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)

binderhubname=${vararray[6]}

# Get IP addresses of both the JupyterHub and BinderHub
echo "Jupyterhub IP: " `kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
echo "Binderhub IP: " `kubectl --namespace=$binderhubname get svc binder | awk '{ print $4}' | tail -n 1`
