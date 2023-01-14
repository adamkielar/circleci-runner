# !/bin/bash
set -o errexit  # exit if some command fails
set -o nounset  # check if all variables are fill
set -o pipefail # exit if some command in pipe fails
set -o xtrace   # print all executed commands

# Get variables
EMAIL="${1}"

# Set env variables
export resourceGroup="circleci-runner-rg"
export aksIdentity="aks-identity"
export aksName="aks-circleci-runner"
export kvName="aks-$RANDOM-kv"
export workloadIdentity="workload-identity"

az group create --name $resourceGroup --location eastus

export appId=$(az identity create --name $aksIdentity --resource-group $resourceGroup --query id --output tsv)

export groupId=$(az ad group create --display-name "AKSADMINS" --mail-nickname "AKSADMINS" --query id -o tsv)

export userId=$(az ad user show --id ${EMAIL} --query id -o tsv)
az ad group member add --group $groupId --member-id $userId

az aks create \
--resource-group $resourceGroup \
--name $aksName \
--location eastus \
--assign-identity $appId \
--enable-managed-identity \
--enable-oidc-issuer \
--enable-workload-identity \
--enable-aad \
--aad-admin-group-object-ids $groupId \
--enable-addons azure-keyvault-secrets-provider \
--node-count 1 \
--node-vm-size "Standard_B2s"

az aks get-credentials --resource-group $resourceGroup --name $aksName

export oidcUrl="$(az aks show --name $aksName --resource-group $resourceGroup --query "oidcIssuerProfile.issuerUrl" -o tsv)"

az keyvault create --name $kvName \
--resource-group $resourceGroup
zsh