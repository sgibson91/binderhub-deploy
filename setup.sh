#!/usr/bin/env bash

# Check sudo availability
sudo_command=`command -v sudo`

## Linux install cases
if [[ ${OSTYPE} == 'linux'* ]] ; then

## apt-based systems
  if command -v apt >/dev/null 2>&1 ; then
    echo "--> Checking system packages and installing any missing packages"
    # Update apt before starting, in case this is a new container
    APTPACKAGES=" \
      curl \
      python \
      openssl \
      jq \
      "
    for package in $APTPACKAGES ; do
      if ! dpkg -s $package > /dev/null ; then
        echo "--> Apt installing $package"
        ${sudo_command} apt update && ${sudo_command} apt install -y $package || { echo >&2 "--> $package install failed; please install manually and re-run this script."; exit 1; }
	fi
    done
    if ! command -v az >/dev/null 2>&1 ; then
      echo "--> Attempting to install Azure-CLI with deb packages"
      curl -sL https://aka.ms/InstallAzureCLIDeb | ${sudo_command} bash || { echo >&2 "--> Azure-CLI install failed; please install manually and re-run this script."; exit 1; }
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "--> Attempting to install kubectl with deb packages"
      ${sudo_command} apt-get update && ${sudo_command} apt-get install -y apt-transport-https
      curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | ${sudo_command} apt-key add -
      echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | ${sudo_command} tee -a /etc/apt/sources.list.d/kubernetes.list
      ${sudo_command} apt-get update && ${sudo_command} apt-get install -y kubectl || { echo >&2 "--> kubectl install failed; please install manually and re-run this script."; exit 1; }
    fi

## yum-based systems
  elif command -v yum >/dev/null 2>&1 ; then
    if [ "$(cat /etc/redhat-release | grep -i centos)" ] ; then
      echo "***************************************************************"
      echo "* You appear to be running CentOS. A required package, jq, is *"
      echo "* not available from core repositories but can be installed   *"
      echo "* from the epel-release repository. If a jq install fails,    *"
      echo "* run the following command as root (or with sudo) to enable  *"
      echo "* the epel repository:                                        *"
      echo "*                                                             *"
      echo "*                  yum -y install epel-release                *"
      echo "*                                                             *"
      echo "***************************************************************"
    fi
    echo "--> Checking system packages and installing any missing packages"
    YUMPACKAGES=" \
      jq \
      curl \
      python \
      tar \
      which \
      openssl \
      "
    for package in $YUMPACKAGES ; do
      if ! rpm -q $package > /dev/null ; then
        echo "--> Yum installing $package"
        ${sudo_command} yum install -y $package || { echo >&2 "--> $package install failed; please install manually and re-run this script."; exit 1; }
      fi
    done
    if ! command -v az >/dev/null 2>&1 ; then
      echo "--> Attempting to install Azure-CLI with yum packages"
      ${sudo_command} rpm --import https://packages.microsoft.com/keys/microsoft.asc
      ${sudo_command} sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
      ${sudo_command} yum install -y azure-cli || { echo >&2 "--> Azure-CLI install failed; please install manually and re-run this script."; exit 1; }
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "--> Attempting to install kubectl with yum packages"
      echo "[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
" | ${sudo_command} tee /etc/yum.repos.d/kubernetes.repo
      ${sudo_command} yum install -y kubectl || { echo >&2 "--> kubectl install failed; please install manually and re-run this script."; exit 1; }
    fi

## zypper-based systems
  elif command -v zypper >/dev/null 2>&1 ; then
    echo "--> Checking system packages and installing any missing packages"
    ZYPPERPACKAGES=" \
      curl \
      python \
      tar \
      which \
      jq \
      openssl \
      "
    for package in $ZYPPERPACKAGES ; do
      if ! rpm -q $package > /dev/null ; then
        echo "--> Zypper installing $package"
        ${sudo_command} zypper install -y $package || { echo >&2 "--> $package install failed; please install manually and re-run this script."; exit 1; }
	fi
    done
    if ! command -v az >/dev/null 2>&1 ; then
      echo "--> Attempting to install Azure-CLI with zypper packages"
      ${sudo_command} rpm --import https://packages.microsoft.com/keys/microsoft.asc
      ${sudo_command} zypper addrepo --name 'Azure CLI' --check https://packages.microsoft.com/yumrepos/azure-cli azure-cli
      ${sudo_command} zypper install --from azure-cli -y azure-cli || { echo >&2 "--> azure-cli install failed; please install manually and re-run this script."; exit 1; }
      # The az-cli installer misses python-xml dependency on suse
      ${sudo_command} zypper install -y python-xml || { echo >&2 "--> python-xml install failed; please install manually and re-run this script."; exit 1; }
    fi
    if ! command -v kubectl >/dev/null 2>&1 ; then
      echo "--> Attempting to install kubectl with zypper packages"
      zypper ar -f https://download.opensuse.org/tumbleweed/repo/oss/ factory
      zypper install -y kubectl || { echo >&2 "--> kubectl install failed; please install manually and re-run this script."; exit 1; }
    fi

## pacman-based systems
  elif command -v pacman >/dev/null 2>&1 ; then
    echo "--> Checking system packages and installing any missing packages"
    PACMANPACKAGES=" \
      curl \
      python \
      tar \
      which \
      jq \
      gcc \
      awk \
      grep \
      openssl \
      kubectl \
      "
    for package in $PACMANPACKAGES ; do
      if ! pacman -Q $package 2> /dev/null ; then
        echo "--> pacman installing $package"
        ${sudo_command} pacman -Sy --noconfirm $package || { echo >&2 "--> $package install failed; please install manually and re-run this script."; exit 1; }
	fi
    done
    if ! command -v az >/dev/null 2>&1 ; then
      echo "--> Attempting to install Azure-CLI with curl"
      curl -L https://aka.ms/InstallAzureCli | sh || { echo >&2 "--> Azure-CLI install failed; please install manually and re-run this script."; exit 1; }
    fi

## Mystery linux system without any of our recognised package managers
  else
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v awk >/dev/null 2>&1 || { echo >&2 "awk not found; please install and re-run this script."; exit 1; }
    command -v grep >/dev/null 2>&1 || { echo >&2 "grep not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo >&2 "jq not found; please install and re-run this script."; exit 1; }
    echo "--> Attempting to install Azure-CLI with curl"
    if ! command -v az >/dev/null 2>&1 ; then
      curl -L https://aka.ms/InstallAzureCli | sh || { echo >&2 "--> Azure-CLI install failed; please install manually and re-run this script."; exit 1; }
    fi
    echo "--> Attempting to install kubectl with curl"
    if ! command -v kubectl >/dev/null 2>&1 ; then
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl || { echo >&2 "--> kubectl download failed; please install manually and re-run this script."; exit 1; }
      chmod +x ./kubectl
      ${sudo_command} mv ./kubectl /usr/local/bin/kubectl
    fi
  fi

## Helm isn't well packaged for Linux, alas
  if ! command -v helm >/dev/null 2>&1 ; then
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v awk >/dev/null 2>&1 || { echo >&2 "awk not found; please install and re-run this script."; exit 1; }
    command -v grep >/dev/null 2>&1 || { echo >&2 "grep not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo >&2 "tar not found; please install and re-run this script."; exit 1; }
    command -v which >/dev/null 2>&1 || { echo >&2 "which not found; please install and re-run this script."; exit 1; }
    echo "--> Helm doesn't have a system package; attempting to install with curl"
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh || { echo >&2 "--> helm install failed; please install manually and re-run this script."; exit 1; }
  fi

## Installing on OS X
elif [[ ${OSTYPE} == 'darwin'* ]] ; then
  if command -v brew >/dev/null 2>&1 ; then
    echo "--> Checking brew packages and installing any missing packages"
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
        echo "--> Brew installing $package"
        brew update && brew install $package || { echo >&2 "--> $package install failed; please install manually and re-run this script."; exit 1; }
	fi
    done
  else
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found; please install and re-run this script."; exit 1; }
    command -v python >/dev/null 2>&1 || { echo >&2 "python not found; please install and re-run this script."; exit 1; }
    command -v tar >/dev/null 2>&1 || { echo >&2 "tar not found; please install and re-run this script."; exit 1; }
    command -v which >/dev/null 2>&1 || { echo >&2 "which not found; please install and re-run this script."; exit 1; }
    echo "--> Attempting to install Azure-CLI with curl"
    if ! command -v az >/dev/null 2>&1  ; then
      curl -L https://aka.ms/InstallAzureCli | sh || { echo >&2 "--> Azure-CLI install failed; please install manually and re-run this script."; exit 1; }
    fi
    echo "--> Attempting to install kubectl with curl"
    if ! command -v kubectl >/dev/null 2>&1 ; then
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl || { echo >&2 "--> kubectl download failed; please install manually and re-run this script."; exit 1; }
      chmod +x ./kubectl
      ${sudo_command} mv ./kubectl /usr/local/bin/kubectl
    fi
    echo "--> Attempting to install helm with curl"
    if ! command -v helm >/dev/null 2>&1 ; then
      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
      chmod 700 get_helm.sh
      ./get_helm.sh || { echo >&2 "--> helm install failed; please install manually and re-run this script."; exit 1; }
    fi
  fi
fi
