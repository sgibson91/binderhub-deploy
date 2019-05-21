#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -e

# Are we running in a container deploy environment?
if [ -z $BINDERHUB_CONTAINER_MODE ] ; then
  # Ask for user's Docker credentials
  echo "If you have provided a DockerHub organisation, this Docker ID MUST be a member of that organisation"
  read -p "DockerHub ID: " DOCKER_USERNAME
  read -sp "DockerHub password: " DOCKER_PASSWORD

  # Read config file and get values
  configFile='config.json'

  BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
  BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`
  DOCKER_ORGANISATION=`jq -r '.docker .org' ${configFile}`
  DOCKER_IMAGE_PREFIX=`jq -r '.docker .image_prefix' ${configFile}`

# Create tokens for the secrets file:
apiToken=`openssl rand -hex 32`
secretToken=`openssl rand -hex 32`

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub:
python3 create_config.py -id=$DOCKER_USERNAME --prefix=$prefix -org=$DOCKER_ORGANISATION --force
python3 create_secret.py --apiToken=$apiToken --secretToken=$secretToken -id=$DOCKER_USERNAME --password=$DOCKER_PASSWORD --force
helm install jupyterhub/binderhub --version=$BINDERHUB_VERSION --name=$BINDERHUB_NAME --namespace=$BINDERHUB_NAME -f secret.yaml -f config.yaml

# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
jupyterhub_ip=`kubectl --namespace=$BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1`
while [ "$jupyterhub_ip" = '<pending>' ] || [ "$jupyterhub_ip" = "" ]
do
    echo "JupyterHub IP: $jupyterhub_ip"
    sleep 5
    jupyterhub_ip=`kubectl --namespace=$BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1`
done
python3 create_config.py -id=$DOCKER_USERNAME --prefix=$prefix -org=$DOCKER_ORGANISATION --jupyterhub_ip=$jupyterhub_ip --force
helm upgrade $BINDERHUB_NAME jupyterhub/binderhub --version=$BINDERHUB_VERSION -f secret.yaml -f config.yaml
