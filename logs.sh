#!/usr/bin/env bash

# Read config.json and get BinderHub name
outputs=`python read_config.py`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)
binderhubname=${vararray[6]}

# Get pod name of the JupyterHub
output=`kubectl -n $binderhubname get pod | awk '{ print $1}' | tail -n 2`
output=($output)
hubpod=${output[0]}

# Print the JupyterHub logs to the terminal
kubectl logs $hubpod -n $binderhubname
