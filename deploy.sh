#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -e

# Ask for user's Docker credentials
echo "If you have provided a DockerHub organisation, this Docker ID MUST be a member of that organisation"
read -p "DockerHub ID: " id
read -sp "DockerHub password: " password

# Read config file and get values
configFile='config.json'

binderhubname=`jq -r '.binderhub .name' ${configFile}`
version=`jq -r '.binderhub .version' ${configFile}`
org=`jq -r '.docker .org' ${configFile}`
prefix=`jq -r '.docker .image_prefix' ${configFile}`

# Create tokens for the secrets file:
apiToken=`openssl rand -hex 32`
secretToken=`openssl rand -hex 32`

# Get the latest helm chart for BinderHub:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update

# Get this script's path
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Generate the scripts paths - make sure these are found
config_script="${DIR}/create_config.py"
secret_script="${DIR}/create_secret.py"

# Install the Helm Chart using the configuration files, to deploy both a BinderHub and a JupyterHub:
echo "--> Generating initial configuration file"
python3 $config_script -id=$id --prefix=$prefix -org=$org --force

echo "--> Generating initial secrets file"

python3 $secret_script --apiToken=$apiToken \
--secretToken=$secretToken \
-id=$id \
--password=$password \
--force

echo "--> Installing Helm chart"
helm install jupyterhub/binderhub \
--version=$version \
--name=$binderhubname \
--namespace=$binderhubname \
-f ./secret.yaml \
-f ./config.yaml \
--timeout=3600

# Wait for  JupyterHub, grab its IP address, and update BinderHub to link together:
echo "--> Retrieving BinderHub IP"
jupyterhub_ip=`kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
while [ "$jupyterhub_ip" = '<pending>' ] || [ "$jupyterhub_ip" = "" ]
do
    echo "JupyterHub IP: $jupyterhub_ip"
    sleep 5
    jupyterhub_ip=`kubectl --namespace=$binderhubname get svc proxy-public | awk '{ print $4}' | tail -n 1`
done

echo "--> Finalising configurations"
python3 $config_script -id=$id \
--prefix=$prefix \
-org=$org \
--jupyterhub_ip=$jupyterhub_ip \
--force

echo "--> Updating Helm chart"
helm upgrade $binderhubname jupyterhub/binderhub \
--version=$version \
-f secret.yaml \
-f config.yaml
