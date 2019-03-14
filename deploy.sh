#!/bin/bash

# Required inputs:
# * $id: DockerHub ID
# * $prefix: desired image prefix
# * $version: Helm Chart version to deploy
# * $binderhubname: Name/Namespace for the BinderHub

# Optional inputs:
# * $org: DockerHub organisation
# * $secretFile: Path to file containing secrets/passwords

# Exit immediately if a pipeline returns a non-zero status
set -e

# Create tokens for the secrets file:
apiToken=`openssl rand -hex 32`
secretToken=`openssl rand -hex 32`

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub:
outputs=`python deploy.py --apiToken $apiToken --secretToken $secretToken`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)

binderhubname=${vararray[0]}
id=${vararray[1]}
prefix=${vararray[2]}
org=${vararray[3]}
version=${vararray[4]}

# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
jupyterhub_ip=`kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
while [ "$jupyterhub_ip" = '<pending>' ] || [ "$jupyterhub_ip" = "" ]
do
    echo "JupyterHub IP: $jupyterhub_ip"
    sleep 5
    jupyterhub_ip=`kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
done
python create_config.py -id=$id --prefix=$prefix -org=$org --jupyterhub_ip=$jupyterhub_ip --force
helm upgrade $binderhubname jupyterhub/binderhub --version=$version -f secret.yaml -f config.yaml
