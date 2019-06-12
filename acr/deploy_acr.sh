#!/bin/bash

# Exit immediately if a pipeline returns a non-zero status
set -euo pipefail

# Get this script's path
DIR="$( cd "$( dirname "$BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Read in config file and assign variables for the non-container case
configFile="${DIR}/config.json"

echo "--> Reading configuration from ${configFile}"

AKS_NODE_COUNT=`jq -r '.azure .node_count' ${configFile}`
AKS_NODE_VM_SIZE=`jq -r '.azure .vm_size' ${configFile}`
AZURE_SUBSCRIPTION=`jq -r '.azure .subscription' ${configFile}`
BINDERHUB_NAME=`jq -r '.binderhub .name' ${configFile}`
BINDERHUB_VERSION=`jq -r '.binderhub .version' ${configFile}`
CONTACT_EMAIL=`jq -r '.binderhub .contact_email' ${configFile}`
DOCKER_IMAGE_PREFIX=`jq -r '.docker .image_prefix' ${configFile}`
DOCKER_ORGANISATION=`jq -r '.docker .org' ${configFile}`
DOCKER_PASSWORD=`jq -r '.docker .password' ${configFile}`
DOCKER_USERNAME=`jq -r '.docker .username' ${configFile}`
RESOURCE_GROUP_LOCATION=`jq -r '.azure .location' ${configFile}`
RESOURCE_GROUP_NAME=`jq -r '.azure .res_grp_name' ${configFile}`
SP_APP_ID=`jq -r '.azure .sp_app_id' ${configFile}`
SP_APP_KEY=`jq -r '.azure .sp_app_key' ${configFile}`
SP_TENANT_ID=`jq -r '.azure .sp_tenant_id' ${configFile}`

# Check that the variables are all set non-zero, non-null
REQUIREDVARS=" \
        AKS_NODE_COUNT \
        AKS_NODE_VM_SIZE \
        AZURE_SUBSCRIPTION \
        BINDERHUB_NAME \
        BINDERHUB_VERSION \
        CONTACT_EMAIL \
        DOCKER_IMAGE_PREFIX \
        RESOURCE_GROUP_NAME \
        RESOURCE_GROUP_LOCATION \
        "

for required_var in $REQUIREDVARS ; do
  if [ -z "${!required_var}" ] || [ x${required_var} == 'xnull' ] ; then
    echo "--> ${required_var} must be set for deployment" >&2
    exit 1
  fi
done

# Check if any optional variables are set null; if so, reset them to a
# zero-length string for later checks. If they failed to read at all,
# possibly due to an invalid json file, they will be returned as a
# zero-length string -- this is attempting to make the 'not set'
# value the same in either case
if [ x${DOCKER_ORGANISATION} == 'xnull' ] ; then DOCKER_ORGANISATION='' ; fi
if [ x${DOCKER_PASSWORD} == 'xnull' ] ; then DOCKER_PASSWORD='' ; fi
if [ x${DOCKER_USERNAME} == 'xnull' ] ; then DOCKER_USERNAME='' ; fi
if [ x${SP_APP_ID} == 'xnull' ] ; then SP_APP_ID='' ; fi
if [ x${SP_APP_KEY} == 'xnull' ] ; then SP_APP_KEY='' ; fi
if [ x${SP_TENANT_ID} == 'xnull' ] ; then SP_TENANT_ID='' ; fi

# Normalise resource group location to remove spaces and have lowercase
RESOURCE_GROUP_LOCATION=`echo ${RESOURCE_GROUP_LOCATION//[[:blank::]]/} | tr '[:upper:]' '[:lower:]'`

echo "--> Configuration read in:
  AKS_NODE_COUNT: ${AKS_NODE_COUNT}
  AKS_NODE_VM_SIZE: ${AKS_NODE_VM_SIZE}
  AZURE_SUBSCRIPTION: ${AZURE_SUBSCRIPTION}
  BINDERHUB_NAME: ${BINDERHUB_NAME}
  BINDERHUB_VERSION: ${BINDERHUB_VERSION}
  CONTACT_EMAIL: ${CONTACT_EMAIL}
  DOCKER_IMAGE_PREFIX: ${DOCKER_IMAGE_PREFIX}
  DOCKER_ORGANISATION: ${DOCKER_ORGANISATION}
  DOCKER_PASSWORD: ${DOCKER_PASSWORD}
  DOCKER_USERNAME: ${DOCKER_USERNAME}
  RESOURCE_GROUP_LOCATION: ${RESOURCE_GROUP_LOCATION}
  RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}
  SP_APP_ID: ${SP_APP_ID}
  SP_APP_KEY: ${SP_APP_KEY}
  SP_TENANT_ID: ${SP_TENANT_ID}
  "

# Check/get the user's Docker credentials
if [ -z $DOCKER_USERNAME ] ; then
  if [ ! -z "$DOCKER_ORGANISATION" ] ; then
    echo "--> Your Docker IS must be a member of the ${DOCKER_ORGANISATION} organisation"
  fi
  read -p "DockerHub ID: " DOCKER_USERNAME
  read -sp "DockerHub password: " DOCKER_PASSWORD
  echo
else
  if [ -z $DOCKER_PASSWORD ] ; then
    read -sp "DockerHub password for ${DOCKER_USERNAME}: " DOCKER_PASSWORD
    echo
  fi
fi
