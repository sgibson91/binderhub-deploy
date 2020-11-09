#!/bin/bash

set -eo pipefail

# Get this script's path
DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# Read config.json and get BinderHub name
configFile="${DIR}/config.json"
AKS_RESOURCE_GROUP=$(jq -r '.azure .res_grp_name' "${configFile}")
RESOURCE_GROUP_LOCATION=$(jq -r '.azure .location' "${configFile}")
BINDERHUB_NAME=$(jq -r '.binderhub .name' "${configFile}")
DOMAIN_NAME=$(jq -r '.https .domain_name' "${configFile}")
AKS_NAME="${BINDERHUB_NAME}-AKS"

CLUSTER_RESOURCE_GROUP="MC_${AKS_RESOURCE_GROUP}_${AKS_NAME}_${RESOURCE_GROUP_LOCATION}"
echo "Resource Group: ${CLUSTER_RESOURCE_GROUP}"

IP_ADDRESS_NAME="$(az resource list -g "${CLUSTER_RESOURCE_GROUP}" --query "[?type == 'Microsoft.Network/publicIPAddresses'].name" -o tsv | grep ^kubernetes-)"
echo "IP Address: ${IP_ADDRESS_NAME}" | ip-address-name.log

ipAddressAttempts=0
while [ -z "${IP_ADDRESS_NAME}" ]; do
	((ipAddressAttempts++))
	echo "--> IP Address Name pull attempt ${ipAddressAttempts} of 10 failed"
	if ((ipAddressAttempts > 9)); then
		echo "--> Failed to pull the IP Address name. You will have to set the A records manually."
		break
	fi
	echo "--> Waiting 30s before trying again"
	sleep 30
	IP_ADDRESS_NAME="$(az resource list -g "${CLUSTER_RESOURCE_GROUP}" --query "[?type == 'Microsoft.Network/publicIPAddresses'].name" -o tsv | grep ^kubernetes-)"
	echo "IP Address Name: ${IP_ADDRESS_NAME}" | tee ip-address-name.log
done

if [ -n "${IP_ADDRESS_NAME}" ]; then
	IP_ADDRESS_ID="$(az resource show -g "${CLUSTER_RESOURCE_GROUP}" -n "${IP_ADDRESS_NAME}" --resource-type 'Microsoft.Network/publicIPAddresses' --query id -o tsv)"
	echo "IP Address ID: ${IP_ADDRESS_ID}" | tee ip-address-id.log

	az network dns record-set a update -n hub -g "${AKS_RESOURCE_GROUP}" -z "${DOMAIN_NAME}" --target-resource "${IP_ADDRESS_ID}" -o table | tee update-hub-a-record.log
	az network dns record-set a update -n binder -g "${AKS_RESOURCE_GROUP}" -z "${DOMAIN_NAME}" --target-resource "${IP_ADDRESS_ID}" -o table | tee update-binder-a-record.log
fi
