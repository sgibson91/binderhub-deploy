#!/usr/bin/env bash

## Detection of the setup mode 
#
# This script should handle both interactive setup when run by a user
# on their local system, and also running as a container entrypoint when
# used either for a container-based local setup or when deployed via an
# Azure blue button setup.
#
# Check whether BINDERHUB_CONTAINER_MODE is set, and if so assume running
# as a container-based install, checking that all required input is present
# in the form of environment variables

if [ ! -z $BINDERHUB_CONTAINER_MODE ] ; then
  # Set out a list of required variables for this script
  REQUIREDVARS=" \
	  SP_APP_ID \
	  SP_APP_KEY \
	  SP_TENANT_ID \
	  RESOURCE_GROUP_NAME \
	  RESOURCE_GROUP_LOCATION \
	  AZURE_SUBSCRIPTION \
          BINDERHUB_NAME \
          BINDERHUB_VERSION \
	  AKS_NODE_COUNT \
	  AKS_NODE_VM_SIZE \
	  CONTACT_EMAIL \
	  DOCKER_USERNAME \
	  DOCKER_PASSWORD \
	  DOCKER_IMAGE_PREFIX \
	  DOCKER_ORGANISATION \
	  "
  for required_var in $REQUIREDVARS ; do
    if [ -z "${!required_var}" ] ; then
      echo "${required_var} must be set for container-based setup" >&2
      exit 1
    fi
  done
fi

# If we're not in a container, check the package environment is sufficient
# for binderhub setup. If anything is missing, attempt to install it.

if [ -z $BINDERHUB_CONTAINER_MODE ] ; then

  # Check sudo availability
  sudo_command=`command -v sudo`
  
  ## Linux install cases
  if [[ ${OSTYPE} == 'linux'* ]] ; then
  
  ## apt-based systems
    if command -v apt >/dev/null 2>&1 ; then
      echo "Checking system packages and installing any missing packages"
      # Update apt before starting, in case this is a new container
      APTPACKAGES=" \
        curl \
        python \
        python3 \
        openssl \
        jq \
        "
      for package in $APTPACKAGES ; do
        if ! dpkg -s $package > /dev/null ; then
          echo "Apt installing $package"
          ${sudo_command} apt update && ${sudo_command} apt install -y $package
	fi
      done
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
      echo "Checking system packages and installing any missing packages"
      YUMPACKAGES=" \
        curl \
        python \
        tar \
	which \
        jq \
	openssl \
        "
      for package in $YUMPACKAGES ; do
        if ! rpm -q $package > /dev/null ; then
          echo "Yum installing $package"
          ${sudo_command} yum install -y $package
	fi
      done
      if ! command -v python3 >/dev/null 2>&1 ; then
        if [ -f /etc/fedora-release ] ; then
          ${sudo_command} yum install -y python3
        else
          ${sudo_command} yum install -y epel-release
          ${sudo_command} yum install -y python36
        fi
      fi
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
      echo "Checking system packages and installing any missing packages"
      ZYPPERPACKAGES=" \
        curl \
        python \
        python3 \
        tar \
        which \
        jq \
	openssl \
        "
      for package in $ZYPPERPACKAGES ; do
        if ! rpm -q $package > /dev/null ; then
          echo "Zypper installing $package"
          ${sudo_command} zypper install -y $package
	fi
      done
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
      command -v jq >/dev/null 2>&1 || { echo >&2 "jq not found; please install and re-run this script."; exit 1; }
      echo "Attempting to install Azure-CLI with curl"
      if ! command -v az >/dev/null 2>&1 ; then
        curl -L https://aka.ms/InstallAzureCli
      fi
      echo "Attempting to install kubectl with curl"
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
      echo "Checking brew packages and installing any missing packages"
      BREWPACKAGES=" \
        curl \
        python \
        azure-cli \
        kubernetes-cli \
        kubernetes-helm \
        jq \
        "
      for package in $BREWPACKAGES ; do
        if ! brew ls --versions $package > /dev/null ; then
          echo "Brew installing $package"
          brew update && brew install $package
	fi
      done
    else
      command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
      command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
      command -v tar >/dev/null 2>&1 || { echo >&2 "tar not found; please install and re-run this script."; exit 1; }
      command -v which >/dev/null 2>&1 || { echo >&2 "which not found; please install and re-run this script."; exit 1; }
      echo "Attempting to install Azure-CLI with curl"
      if ! command -v az >/dev/null 2>&1  ; then
        curl -L https://aka.ms/InstallAzureCli
      fi
      echo "Attempting to install kubectl with curl"
      if ! command -v kubectl >/dev/null 2>&1 ; then
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
        chmod +x ./kubectl
        ${sudo_command} mv ./kubectl /usr/local/bin/kubectl
      fi
      echo "Attempting to install helm with curl"
      if ! command -v helm >/dev/null 2>&1 ; then
        curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
        chmod 700 get_helm.sh
        ./get_helm.sh
      fi
    fi
  fi

  # Read in config file and assign variables for the non-container case
  configFile='config.json'
  
  echo "Reading configuration from ${configFile}"
  AZURE_SUBSCRIPTION=`jq -r '.azure .subscription' ${configFile}`
  BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
  RESOURCE_GROUP_LOCATION=`jq -r '.azure .location' ${configFile}`
  RESOURCE_GROUP_NAME=`jq -r '.azure .res_grp_name' ${configFile}`
  AKS_NODE_COUNT=`jq -r '.azure .node_count' ${configFile}`
  AKS_NODE_VM_SIZE=`jq -r '.azure .vm_size' ${configFile}`

  # Generate resource group name
  RESOURCE_GROUP_NAME=`echo ${BINDERHUB_NAME} | tr -cd '[:alnum:]_-' | cut -c 1-87`_RG

  echo "Configuration read in:
    AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
    BINDERHUB_NAME: ${BINDERHUB_NAME}
    RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
    RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
    AKS_NODE_COUNT: ${AKS_NODE_COUNT}
    AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}"

fi

