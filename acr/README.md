# Quick Notes on the ACR upgrade

The script does not have a container mode yet.
Can only be run locally.

## Creating a Service Principal to deploy ACR

If the Service Principal does not have an "Owner" role, then the Role Assignment step for AcrPush (on [this line](https://github.com/alan-turing-institute/binderhub-deploy/blob/4f8c0b3257d1d76bc82bc9211e41e7ef2484ede2/acr/deploy_acr.sh#L224)) will fail.

```
az login --output none
az account list --refresh --output table
az account set -s "<SUBSCRIPTION>"
az ad sp create-for-rbac --name acr-sp-owner --role Owner --scope /subscription/<SUBSCRIPTION_ID>
```

## Change in the `config.json` template

`image_prefix` **must** be of the form `<project-name>/<prefix>` when deploying an ACR.
This is due to a hard dependency of BinderHub on Google Cloud Registry format: `gcr.io/<gcloud-project-id>/<prefix>-name:tag`.
`<project-name>` can be entirely fictional.

```
{
  "container_registry": "",  // Choose DockerHub or ACR with 'dockerhub' or 'azurecr' values, respectively.
  "azure": {
    "subscription": "",      // Subscription ID
    "res_grp_name": "",      // Resource group name
    "location": "",          // Resource group region
    "node_count": 1,         // Number of nodes to deploy
    "vm_size": "",           // Type of VM to deploy
    "sp_app_id": null,       // Service principal ID
    "sp_app_key": null,      // Service principal key
    "sp_tenant_id": null     // Tenant subscription ID
  },
  "binderhub": {
    "name": "",              // Namespace to deploy BinderHub under
    "version": "",           // Helm Chart version to deploy
    "image_prefix": "",      // Tag to prepend to images
    "contact_email": ""      // For letsencrypt
  },
  "docker": {
    "username": null,        // Docker ID. Required if 'container_registry' = 'dockerhub'.
    "password": null,        // Docker password. See username above.
    "org": null              // Docker organisation Docker ID belongs to (optional).
  },
  "acr": {
    "registry_name": null,   // Name to give the Azure Container Registry
    "sku": "Basic"           // The SKU tier
  }
}
```

## Running the script

```
cd acr
chmod 700 deploy_acr.sh
./deploy_acr.sh
```
