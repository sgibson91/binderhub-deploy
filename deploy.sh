#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -e

# Are we running in a container deploy environment?
if [ -z $BINDERHUB_CONTAINER_MODE ] ; then
  # Ask for user's Docker credentials
  echo "If you have provided a DockerHub organisation, this Docker ID MUST be a member of that organisation"
  read -p "DockerHub ID: " DOCKER_USERNAME
  read -sp "DockerHub password: " DOCKER_PASSWORD

# Read in config file and assign variables
configFile='config.json'

subscription=`jq -r '.azure .subscription' ${configFile}`
res_grp_name=`jq -r '.azure .res_grp_name' ${configFile}`
location=`jq -r '.azure .location' ${configFile}`
cluster_name=`jq -r '.azure .cluster_name' ${configFile}`
node_count=`jq -r '.azure .node_count' ${configFile}`
vm_size=`jq -r '.azure .vm_size' ${configFile}`
binderhubname=`jq -r '.binderhub .name' ${configFile}`
version=`jq -r '.binderhub .version' ${configFile}`
org=`jq -r '.docker .org' ${configFile}`
prefix=`jq -r '.docker .image_prefix' ${configFile}`

# Login to Azure
az login -o none

# Activate chosen subscription
az account set -s "$subscription"

# Create a Resource Group
az group create -n $res_grp_name --location $location -o table

# Create an AKS cluster
az aks create -n $cluster_name -g $res_grp_name --generate-ssh-keys --node-count $node_count --node-vm-size $vm_size -o table

# Get kubectl credentials from Azure
az aks get-credentials -n $cluster_name -g $res_grp_name -o table

# Check nodes are ready
while [[ ! x`kubectl get node | awk '{print $2}' | grep Ready | wc -l` == x${node_count} ]] ; do echo -n $(date) ; echo " : Waiting for all cluster nodes to be ready" ; sleep 15 ; done

# Setup ServiceAccount for tiller
kubectl --namespace kube-system create serviceaccount tiller

# Give the ServiceAccount full permissions to manage the cluster
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

# Initialise helm and tiller
helm init --service-account tiller --wait

# Secure tiller against attacks from within the cluster
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'

# Check helm has been configured correctly
echo "Verify Client and Server are running the same version number:"
while [[ ! x`kubectl get pods --namespace kube-system | grep ^tiller | awk '{print $3}'` == xRunning ]] ; do echo -n $(date) ; echo " : Waiting for tiller pod to be running" ; sleep 5 ; done
helm version

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
    jupyterhub_ip=`kubectl --namespace=$BINDERHUB_NAME get svc proxy-public | awk '{ print $4}' | tail -n 1`
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
