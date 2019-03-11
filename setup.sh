#!/bin/bash

# Shell script to install Azure, Kubernetes and Helm CLIs
# Then deploys and configures a Kubernetes cluster on Microsoft Azure

# Required inputs:
# * $subscription: Azure subscription to deploy onto
# * $res_grp_name: Resource Group Name to deploy into
# * $location: Azure data centre location
# * $cluster_name: Name of Kubernetes cluster
# * $node_count: Number of nodes to deploy
# * $vm_size: Type of VM to deploy

# Install Azure-CLI
curl -L https://aka.ms/InstallAzureCli

# Install kubectl - Kubernetes-CLI
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
# Make the kubectl binary executable
chmod +x ./kubectl
# Move the binary into your PATH
sudo mv ./kubectl /usr/local/bin/kubectl

# Install Helm cli - fetch install script and execute it locally
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# Login to Azure
az login --output table

# Activate chosen subscription
az account set -s "$subscription"

# Create a Resource Group
az group create --name $res_grp_name --location $location --output table

# Make a folder for the cluster
mkdir $cluster_name && cd $cluster_name

# Create an SSH key
ssh-keygen -f ssh-key-$cluster_name

# Create an AKS cluster
az aks create --name $cluster_name --resource-group $res_grp_name --ssh-key-value ssh-key-$cluster_name.pub --node-count $node_count --node-vm-size $vm_size --output table

# Get kubectl credentials from Azure
az aks get-credentials --name $clustername --resource-group $res_grp_name --output table

# Check node is functional
kubectl get node
# TODO: Get above command to only print out the status and wait until status is ready before continuing

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
helm version
