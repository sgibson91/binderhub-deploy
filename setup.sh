#!/bin/bash
# Shell script to install Azure, Kubernetes and Helm CLIs

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
