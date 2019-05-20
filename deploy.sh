#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -e

# Read config file and get values
outputs=`python read_config.py`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)

binderhubname=${vararray[6]}
version=${vararray[7]}
org=${vararray[9]}
prefix=${vararray[10]}


# Ask for user's Docker credentials
echo "If you have provided a DockerHub organisation, this Docker ID MUST be a member of that organisation"
read -p "DockerHub ID: " id
read -sp "DockerHub password: " password

# Create tokens for the secrets file:
apiToken=`openssl rand -hex 32`
secretToken=`openssl rand -hex 32`

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub:
python create_config.py -id=$id --prefix=$prefix -org=$org --force
python create_secret.py --apiToken=$apiToken --secretToken=$secretToken --docker-id=$id --password=$password --force
helm install jupyterhub/binderhub --version={$version --name=$binderhubname --namespace=$binderhubname -f secret.yaml -f config.yaml

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
