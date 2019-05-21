#!/usr/bin/env bash

# Check sudo availability
sudo_command=`command -v sudo`

## Linux install cases
if [[ ${OSTYPE} == 'linux'* ]] ; then

## apt-based systems
  if command -v apt >/dev/null 2>&1 ; then
    # Update apt before starting, in case this is a new container
    ${sudo_command} apt update
    echo "Core package install with apt"
    ${sudo_command} apt install -y curl python tar openssh-client gnupg
    if ! command -v az >/dev/null 2>&1 ; then
      echo "Attempting to install Azure-CLI with deb packages"
      curl -sL https://aka.ms/InstallAzureCLIDeb | ${sudo_command} bash
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "Attempting to install kubectl with deb packages"
      ${sudo_command} apt-get update && ${sudo_command} apt-get install -y apt-transport-https
      curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | ${sudo_command} apt-key add -
      echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | ${sudo_command} tee -a /etc/apt/sources.list.d/kubernetes.list
      ${sudo_command} apt-get update && ${sudo_command} apt-get install -y kubectl
    fi

## yum-based systems
  elif command -v yum >/dev/null 2>&1 ; then
    echo "Core package install with yum"
    ${sudo_command} yum install -y curl python openssh-clients openssl tar which
    if ! command -v az >/dev/null 2>&1 ; then
      echo "Attempting to install Azure-CLI with yum packages"
      ${sudo_command} rpm --import https://packages.microsoft.com/keys/microsoft.asc
      ${sudo_command} sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
      ${sudo_command} yum install -y azure-cli
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "Attempting to install kubectl with yum packages"
      echo "[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
" | ${sudo_command} tee /etc/yum.repos.d/kubernetes.repo
      ${sudo_command} yum install -y kubectl
    fi

## zypper-based systems
  elif command -v zypper >/dev/null 2>&1 ; then
    echo "Core packages install with zypper"
    ${sudo_command} zypper install -y curl python tar which openssh
    if ! command -v az >/dev/null 2>&1 ; then
      echo "Attempting to install Azure-CLI with zypper packages"
      ${sudo_command} rpm --import https://packages.microsoft.com/keys/microsoft.asc
      ${sudo_command} zypper addrepo --name 'Azure CLI' --check https://packages.microsoft.com/yumrepos/azure-cli azure-cli
      ${sudo_command} zypper install --from azure-cli -y azure-cli
      # The az-cli installer misses python-xml dependency on suse
      ${sudo_command} zypper install -y python-xml
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "Attempting to install kubectl with zypper packages"
      zypper ar -f https://download.opensuse.org/tumbleweed/repo/oss/ factory
      zypper install -y kubectl
    fi

## Mystery linux system without any of our recognised package managers
  else
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    ##command -v ssh-keygen >/dev/null 2>&1 || { echo >&2 "ssh-keygen not found; please install and re-run this script."; exit 1; }
    echo "Package manager not found; installing with curl"
    if ! command -v az >/dev/null 2>&1 ; then
      curl -L https://aka.ms/InstallAzureCli
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
      chmod +x ./kubectl
      ${sudo_command} mv ./kubectl /usr/local/bin/kubectl
    fi
  fi

## Helm isn't well packaged for Linux, alas
  if ! command -v helm >/dev/null 2>&1 ; then
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo >&2 "tar not found; please install and re-run this script."; exit 1; }
    command -v which >/dev/null 2>&1 || { echo >&2 "which not found; please install and re-run this script."; exit 1; }
    echo "Helm doesn't have a system package; attempting to install with curl"
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh
  fi

## Installing on OS X
elif [[ ${OSTYPE} == 'darwin'* ]] ; then
  if command -v brew >/dev/null 2>&1 ; then
    echo "Brew installing required packages"
    brew update && \
      brew install curl python azure-cli kubernetes-cli kubernetes-helm
  else
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo >&2 "tar not found; please install and re-run this script."; exit 1; }
    command -v which >/dev/null 2>&1 || { echo >&2 "which not found; please install and re-run this script."; exit 1; }
    if ! command -v az >/dev/null 2>&1  ; then
      curl -L https://aka.ms/InstallAzureCli
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
      chmod +x ./kubectl
      ${sudo_command} mv ./kubectl /usr/local/bin/kubectl
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
      chmod 700 get_helm.sh
      ./get_helm.sh
    fi
  fi
fi

# Read in config file and assign variables
outputs=`python read_config.py`
vars=$(echo $outputs | tr "(',)" "\n")
vararray=($vars)

subscription=${vararray[0]}
res_grp_name=${vararray[1]}
location=${vararray[2]}
cluster_name=${vararray[3]}
node_count=${vararray[4]}
vm_size=${vararray[5]}

# Login to Azure
az login -o none

# Activate chosen subscription
az account set -s "$subscription"

# Create a Resource Group
az group create -n $res_grp_name --location $location -o table

# Make a secret folder and a sub-folder for the cluster
##mkdir -p .secret && cd .secret && mkdir -p $cluster_name && cd $cluster_name

# Create an SSH key
##ssh-keygen -f ssh-key-$cluster_name

# Create an AKS cluster
az aks create -n $cluster_name -g $res_grp_name --generate-ssh-key --node-count $node_count --node-vm-size $vm_size -o table

# Get kubectl credentials from Azure
az aks get-credentials -n $cluster_name -g $res_grp_name -o table

# Check node is functional
# TODO: Get above command to only print out the status and wait until status is ready before continuing
kubectl get node

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
