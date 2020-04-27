# Automatically deploy a BinderHub to Microsoft Azure

![mit_license_badge](https://img.shields.io/badge/License-MIT-yellow.svg) [![Build Status](https://travis-ci.org/alan-turing-institute/binderhub-deploy.svg?branch=master)](https://travis-ci.org/alan-turing-institute/binderhub-deploy) ![GitHub Action Status - Shellcheck](https://github.com/alan-turing-institute/binderhub-deploy/workflows/shellcheck/badge.svg) ![GitHub Action Status - Yamllint](https://github.com/alan-turing-institute/binderhub-deploy/workflows/yamllint/badge.svg)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-4-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

[BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) is a cloud-based, multi-server technology used for hosting repoducible computing environments and interactive Jupyter Notebooks built from code repositories.

This repo contains a set of scripts to automatically deploy a BinderHub onto [Microsoft Azure](https://azure.microsoft.com/en-gb/), and connect either a [Docker Hub](https://hub.docker.com/) account/organisation or an [Azure Container Registry](https://azure.microsoft.com/en-gb/services/container-registry/), so that you can host your own [Binder](https://mybinder.readthedocs.io/en/latest/) service.

This repo is based on the following set of deployment scripts for Google Cloud: [nicain/binder-deploy](https://github.com/nicain/binder-deploy)

You will require a Microsoft Azure account and subscription.
A Free Trial subscription can be obtained [here](https://azure.microsoft.com/en-gb/free/).
You will be asked to provide a credit card for verification purposes.
**You will not be charged.**
Your resources will be frozen once your subscription expires, then deleted if you do not reactivate your account within a given time period.
If you are building a BinderHub as a service for an organisation, your institution may already have an Azure account.
You should contact your IT Services for further information regarding permissions and access (see the [Service Principal Creation](#service-principal-creation) section below).

## Table of Contents

- [Usage](#usage)
  - [Choosing between Docker Hub and Azure Container Registry](#Choosing-between-Docker-Hub-and-Azure-Container-Registry)
  - [`setup.sh`](#setupsh)
  - [`deploy.sh`](#deploysh)
  - [`logs.sh`](#logssh)
  - [`info.sh`](#infosh)
  - [`upgrade.sh`](#upgradesh)
  - [`teardown.sh`](#teardownsh)
- ["Deploy to Azure" Button](#deploy-to-azure-button)
  - [Service Principal Creation](#service-principal-creation)
  - [Monitoring Deployment Progress](#monitoring-deployment-progress)
  - [Retrieving Deployment Output from Azure](#retrieving-deployment-output-from-azure)
  - [Accessing your BinderHub after Deployment](#accessing-your-binderhub-after-deployment)
- [Running the Container Locally](#Running-the-Container-Locally)
- [Customising your BinderHub Deployment](#customising-your-binderhub-deployment)
- [Developers Guide](#developers-guide)
  - [Building the Docker image for testing](#building-the-docker-image-for-testing)
  - [Tagging a Release](#tagging-a-release)
- [Contributors](#contributors)

---

## Usage

This repo can either be run locally or as "Platform as a Service" through the "Deploy to Azure" button in the ["Deploy to Azure" Button](#deploy-to-azure-button) section.

To use these scripts locally, clone this repo and change into the directory.

```bash
git clone https://github.com/alan-turing-institute/binderhub-deploy.git
cd binderhub-deploy
```

To make the scripts executable and then run them, do the following:

```bash
chmod 700 <script-name>.sh
./<script-name>.sh
```

[**NOTE:** The above command is UNIX specific. If you are running Windows 10, [this blog post](https://www.windowscentral.com/how-install-bash-shell-command-line-windows-10) discusses using a bash shell in Windows.]

To build the BinderHub, you should run `setup.sh` first (to install the required command line tools), then `deploy.sh` (which will build the BinderHub).
Once the BinderHub is deployed, you can run `logs.sh` and `info.sh` to get the JupyterHub logs and IP addresses respectively.
`teardown.sh` should _only_ be used to delete your BinderHub deployment.

You need to create a file called `config.json` which has the format described in the code block below.
Fill the quotation marks with your desired namespaces, etc.
`config.json` is git-ignored so sensitive information, such as passwords and Service Principals, cannot not be pushed to GitHub.

- For a list of available data centre regions, [see here](https://azure.microsoft.com/en-gb/global-infrastructure/locations/).
  This should be a _region_ and **not** a _location_, for example "West Europe" or "Central US".
  These can be equivalently written as `westeurope` and `centralus`, respectively.
- For a list of available Linux Virtual Machines, [see here](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/sizes-general).
  This should be something like, for example `Standard_D2s_v3`.
- The versions of the BinderHub Helm Chart can be found [here](https://jupyterhub.github.io/helm-chart/#development-releases-binderhub) and are of the form `0.2.0-<commit-hash>`.
  It is advised to select the most recent version unless you specifically require an older one.
- If you are deploying an Azure Container Registry, find out more about the SKU tiers [here](https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-skus).

```json
{
  "container_registry": "",        // Choose Docker Hub or ACR with 'dockerhub' or 'azurecr' values, respectively.
  "azure": {
    "subscription": "",            // Azure subscription name or ID (a hex-string)
    "res_grp_name": "",            // Azure Resource Group name
    "location": "",                // Azure Data Centre region
    "node_count": 1,               // Number of nodes to deploy. 3 is preferrable for a stable cluster, but may be liable to caps.
    "vm_size": "Standard_D2s_v3",  // Azure virtual machine type to deploy
    "sp_app_id": null,             // Azure service principal ID (optional)
    "sp_app_key": null,            // Azure service principal password (optional)
    "sp_tenant_id": null,          // Azure tenant ID (optional)
    "log_to_blob_storage": false   // Store logs in blob storage when not running from a container
  },
  "binderhub": {
    "name": "",                    // Name of your BinderHub
    "version": "",                 // Helm chart version to deploy, should be 0.2.0-<commit-hash>
    "image_prefix": ""             // The prefix to preppend to Docker images (e.g. "binder-prod")
  },
  "docker": {
    "username": null,              // Docker username (can be supplied at runtime)
    "password": null,              // Docker password (can be supplied at runtime)
    "org": null                    // A Docker Hub organisation to push images to (optional)
  },
  "acr": {
    "registry_name": null,         // Name to give the ACR. This must be alpha-numerical and unique to Azure.
    "sku": "Basic"                 // The SKU capacity and pricing tier for the ACR
  }
}
```

You can copy [`template-config.json`](./template-config.json) should you require.

**Please note that all entries in `template-config.json` must be surrounded by double quotation marks (`"`), with the exception of `node_count`.**

#### Important for Free Trial subscriptions

If you have signed up to an Azure Free Trial subscription, you are not allowed to deploy more than 4 **cores**.
How many cores you deploy depends on your choice of `node_count` and `vm_size`.

For example, a `Standard_D2s_v3` machine has 2 cores.
Therefore, setting `node_count` to 2 will deploy 4 cores and you will have reached your quota for cores on your Free Trial subscription.

### Choosing between Docker Hub and Azure Container Registry

To select either a Docker Hub account/organisation or an Azure Container Registry (ACR), you must set the top-level `container_registry` key in `config.json` to either `dockerhub` or `azurecr` respectively.
This will tell `deploy.sh` which variables and YAML templates to use.
Then fill in the values under either the `dockerhub` or `acr` key as required.

Using a Docker Hub account/organisation has the benefit of being relatively simple to set up.
However, all the BinderHub images pushed there will be publicly available.
For a few extra steps, deploying an ACR will allow the BinderHub images to be pushed to a private repository.

#### Important Caveats when deploying an ACR

**Service Principal:**

In the [Service Principal Creation](#Service-Principal-Creation) section, we cover how to create a Service Principal in order to deploy a BinderHub.
When following these steps, the `--role` argument of `Contributor` should be replaced with `Owner`.
This is because the Service Principal will need the [`AcrPush`](https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#acrpush) role in order to push images to the ACR and the `Contributor` role does not have permission to create new role assignments.

### `setup.sh`

This script checks whether the required command line tools are already installed.
If any are missing, the script uses the system package manager or [`curl`](https://curl.haxx.se/docs/) to install the command line interfaces (CLIs).
The CLIs to be installed are:

- [Microsoft Azure (`azure-cli`)](https://docs.microsoft.com/en-gb/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
- [Kubernetes (`kubectl`)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl)
- [Helm (`helm`)](https://helm.sh/docs/using_helm/#from-script)

Any dependencies that are not automatically installed by these packages will also be installed.

### `deploy.sh`

This script reads in values from `config.json` and deploys a Kubernetes cluster.
It then creates `config.yaml` and `secret.yaml` files which are used to install the BinderHub using the templates in the [`templates` folder](./templates/).

If you have chosen a Docker Hub account/organisation, the script will ask for your Docker ID and password if you haven't supplied them in the config file.
The ID is your Docker username, **NOT** the associated email.
If you have provided a Docker organisation in `config.json`, then Docker ID **MUST** be a member of this organisation.

If you have chosen an ACR, the script will create one and assign the `AcrPush` role to your Service Principal.
The registry server and Service Principal credentials will then be parsed into `config.yaml` and `secret.yaml` so that the BinderHub can connect to the ACR.

Both a JupyterHub and BinderHub are installed via a Helm Chart onto the deployed Kubernetes cluster and the `config.yaml` file is updated with the JupyterHub IP address.

`config.yaml` and `secret.yaml` are both git-ignored so that secrets cannot be pushed back to GitHub.

The script also outputs log files (`<file-name>.log`) for each stage of the deployment.
These files are also git-ignored.

If the `azure.log_to_blob_storage` value in `config.json` is set to `true` the script is running from the command line, then the log files will be stored in blob storage.

### `logs.sh`

This script will print the JupyterHub logs to the terminal to assist with debugging issues with the BinderHub.
It reads from `config.json` in order to get the BinderHub name.

### `info.sh`

This script will print the pod status of the Kubernetes cluster and the IP addresses of both the JupyterHub and BinderHub to the terminal.
It reads the BinderHub name from `config.json`.

### `upgrade.sh`

This script will automatically upgrade the Helm Chart deployment configuring the BinderHub and then prints the Kubernetes pods.
It reads the BinderHub name and Helm Chart version from `config.json`.

### `teardown.sh`

This script will purge the Helm Chart release, delete the Kubernetes namespace and then delete the Azure Resource Group containing the computational resources.
It will read the namespaces from `config.json`.
The user should check the [Azure Portal](https://portal.azure.com/) to verify the resources have been deleted.
It will also purge the cluster information from your `kubectl` configuration file.

## "Deploy to Azure" Button

To deploy [BinderHub](https://binderhub.readthedocs.io/) to Azure in a single click (and some form-filling), use the deploy button below.

[![Deploy to Azure](https://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falan-turing-institute%2Fbinderhub-deploy%2Fmaster%2Fazure%2Fpaas%2Farm%2Fazure.deploy.json)

### Service Principal Creation

You will be asked to provide a [Service Principal](https://docs.microsoft.com/en-gb/azure/active-directory/develop/app-objects-and-service-principals) in the form launched when you click the "Deploy to Azure" button above.

[**NOTE:** The following instructions can also be run in a local terminal session.
They will require the Azure command line to be installed, so make sure to run [`setup.sh`](./setup.sh) first.]

To create a Service Principal, go to the [Azure Portal](https://portal.azure.com/) (and login!) and open the Cloud Shell:

![Open Shell in Azure](images/open_shell_in_azure.png)

You may be asked to create storage when you open the shell.
This is expected, click "Create".

Make sure the shell is set to Bash, not PowerShell.

![Bash Shell](images/bash_shell.png)

Set the subscription you'd like to deploy your BinderHub on.

```bash
az account set --subscription <subscription>
```

This image shows the command being executed for an "Azure Pass - Sponsorship" subscription.

![Set Subscription](images/set_subscription.png)

You will need the subscription ID, which you can retrieve by running:

```bash
az account list --refresh --output table
```

![List Subscriptions](images/az_account_list.png)

Next, create the Service Principal with the following command.
Make sure to give it a sensible name!

```bash
az ad sp create-for-rbac \
    --name binderhub-sp \
    --role Contributor \
    --scope /subscriptions/<subscription ID from above>
```

**NOTE:** If you are deploying an ACR rather than connecting to Docker Hub, then this command should be:

```bash
az ad sp create-for-rbac \
    --name binder\
    --scope /subscriptions/<subscription ID from above>
```

![Create Service Principal](images/create-for-rbac.png)

The fields `appId`, `password` and `tenant` are the required pieces of information.
These should be copied into the "Service Principal App ID", "Service Principal App Key" and "Service Principal Tenant ID" fields in the form, respectively.

**Keep this information safe as the password cannot be recovered after this step!**

### Monitoring Deployment Progress

To monitor the progress of the blue-button deployment, go to the [Azure portal](https://portal.azure.com/) and select "Resource Groups" from the left hand pane.
Then in the central pane select the resource group you chose to deploy into.

![Select Resource Group](images/select_resource_group.png)

This will give you a right hand pane containing the resources within the group.
You may need to "refresh" until you see a new container instance.

![Select Container Instance](images/select_container_instance.png)

When it appears, select it and then in the new pane go to "Settings->Containers".
You should see your new container listed.

![Container Events](images/container_events.png)

Select it, then in the lower right hand pane select "Logs".
You may need to "refresh" this to display the logs until the container starts up.
The logs are also not auto-updating, so keep refreshing them to see progress.

![Container Logs](images/container_logs.png)

### Retrieving Deployment Output from Azure

When BinderHub is deployed using the "Deploy to Azure" button (or with a local container), output logs, YAML files, and ssh keys are pushed to an Azure storage account to preserve them once the container exits.
The storage account is created in the same resource group as the Kubernetes cluster, and files are pushed into a storage blob within the account.

Both the storage blob name and the storage account name are derived from the name you gave to your BinderHub instance, but may be modified and/or have a random seed appended.
To find the storage account name, navigate to your resource group by selecting "Resource Groups" in the left-most panel of the [Azure Portal](https://portal.azure.com/), then clicking on the resource group containing your BinderHub instance.
Along with any pre-existing resources (for example, if you re-used an existing resource group), you should see three new resources: a container instance, a Kubernetes service, and a storage account.
Make a note of the name of the storage account (referred to in the following commands as `ACCOUNT_NAME`) then select this storage account.

![Storage Account](images/storage_account.png)

In the new pane that opens, select "Blobs" from the "Services" section.
You should see a single blob listed.
Make a note of the name of this blob, which will be `BLOB_NAME` in the following commands.

![Blob Storage](images/blob_storage.png)

![Select Blob Storage](images/select_blob_storage.png)

The Azure CLI can be used to fetch files from the blob (either in the cloud shell in the [Azure Portal](https://portal.azure.com), or in a local terminal session if you've run [`setup.sh`](.setup.sh) first).
Files are fetched into a local directory, **which must already exist**, referred to as `OUTPUT_DIRECTORY` in the following commands.

You can run [`setup.sh`](./setup.sh) to install the Azure CLI or use the cloud shell on the [Azure Portal](https://portal.azure.com).

To fetch all files:

```bash
az storage blob download-batch \
    --account-name <ACCOUNT_NAME> \
    --source <BLOB_NAME> \
    --pattern "*" \
    --destination "<OUTPUT_DIRECTORY>"
```

The `--pattern` argument can be used to fetch particular files, for example all log files:

```bash
az storage blob download-batch \
    --account-name <ACCOUNT_NAME> \
    --source <BLOB_NAME> \
    --pattern "*.log" \
    --destination "<OUTPUT_DIRECTORY>"
```

To fetch a single file, specify `REMOTE_FILENAME` for the name of the file in blob storage, and `LOCAL_FILENAME` for the filename it will be fetched into:

```bash
az storage blob download \
    --account-name <ACCOUNT_NAME> \
    --container-name <BLOB_NAME> \
    --name <REMOTE_FILENAME> \
    --file <LOCAL_FILENAME>
```

For full documentation, see the [`az storage blob` documentation](https://docs.microsoft.com/en-gb/cli/azure/storage/blob?view=azure-cli-latest).

### Accessing your BinderHub after Deployment

Once the deployment has succeeded and you've downloaded the log files, visit the IP address of your Binder page to test it's working.

The Binder IP address can be found by running the following:

```bash
cat <OUTPUT_DIRECTORY>/binder-ip.log
```

A good repository to test your BinderHub with is [binder-examples/requirements](https://github.com/binder-examples/requirements)

## Running the Container Locally

The third way to deploy BinderHub to Azure would be to pull the Docker image and run it directly, parsing the values you would have entered in `config.json` as environment variables.

You will need the Docker CLI installed.
Installation instructions can be found [here](https://docs.docker.com/v17.12/install/).

First, pull the `binderhub-setup` image.

```bash
docker pull sgibson91/binderhub-setup:<TAG>
```

where `<TAG>` is your chosen image tag.

A list of availabe tags can be found [here](https://cloud.docker.com/repository/docker/sgibson91/binderhub-setup/tags).
It is recommended to use the most recent version number.
The `latest` tag is the most recent build from `master` branch and may be subject fluctuations.

Then, run the container with the following arguments, replacing the `<>` fields as necessary:

```bash
docker run \
-e "AKS_NODE_COUNT=1" \  # Required
-e "AKS_NODE_VM_SIZE=Standard_D2s_v3" \  # Required
-e "AZURE_SUBSCRIPTION=<Azure Subscription ID>" \  # Required
-e "BINDERHUB_CONTAINER_MODE=true" \  # Required
-e "BINDERHUB_NAME=<Chosen BinderHub name>" \  # Required
-e "BINDERHUB_VERSION=<Chosen BinderHub version>" \  # Required
-e "CONTAINER_REGISTRY=<dockerhub or azurecr>" \  # Required
-e "DOCKER_IMAGE_PREFIX=binder-dev" \  # Required
-e "DOCKERHUB_ORGANISATION=<Docker organisation>" \
-e "DOCKERHUB_PASSWORD=<Docker password>" \
-e "DOCKERHUB_USERNAME=<Docker ID>" \
-e "REGISTRY_NAME=<Registry Name>" \
-e "REGISTRY_SKU=Basic" \
-e "RESOURCE_GROUP_LOCATION=westeurope" \  # Required
-e "RESOURCE_GROUP_NAME=<Chosen Resource Group name>" \  # Required
-e "SP_APP_ID=<Service Principal ID>" \  # Required
-e "SP_APP_KEY=<Service Principal Key>" \  # Required
-e "SP_TENANT_ID=<Service Principal Tenant ID>" \  # Required
-it sgibson91/binderhub-setup:<TAG>
```

The output will be printed to your terminal and the files will be pushed to blob storage, as in the button deployment.
See the [Retrieving Deployment Output from Azure](#Retrieving-Deployment-Output-from-Azure) section for how to return these files.

## Customising your BinderHub Deployment

Customising your BinderHub deployment is as simple as editing `config.yaml` and/or `secret.yaml` and then upgrading the BinderHub Helm Chart.
The Helm Chart can be upgraded by running [`upgrade.sh`](./upgrade.sh) (make sure you have the CLIs installed by running [`setup.sh`](./setup.sh) first).

The Jupyter guide to customising the underlying JupyterHub can be found [here](https://zero-to-jupyterhub.readthedocs.io/en/latest/extending-jupyterhub.html).

The BinderHub guide for changing the landing page logo can be found [here](https://binderhub.readthedocs.io/en/latest/customizing.html#template-customization).

## Developers Guide

### Building the Docker image for testing

The Docker image will automatically be built by Docker Hub when new pushes are made to `master`.
However, a developer may wish to build the image to test deployments before merging code.

Firstly, make sure `config.json` has been removed from the repository.
Otherwise, secrets within the file may be built into the image.

The command to build a Docker image from the root of the repo is as follows.

```bash
docker build -t <DOCKER_USERNAME>/binderhub-setup:<TAG> .
```

It is not necessary to push this image to a container registry.
But if you choose to do so, the command is as follows.

```bash
docker push <REGISTRY-HOST>/<DOCKER-USERNAME>/binderhub-setup:<TAG>
```

### Tagging a Release

Docker Hub will automatically build the image from the repo with every push to `master` and tag this as `latest`.

To release a specific version, update the [Azure ARM template](https://github.com/alan-turing-institute/binderhub-deploy/blob/master/azure/paas/arm/azure.deploy.json) with the new/desired version on line [123](https://github.com/alan-turing-institute/binderhub-deploy/blob/7206a4dc35b59a260746315ef4fa0a5e995b79fa/azure/paas/arm/azure.deploy.json#L123) and block [L127-L137](https://github.com/alan-turing-institute/binderhub-deploy/blob/7206a4dc35b59a260746315ef4fa0a5e995b79fa/azure/paas/arm/azure.deploy.json#L127-L137).
We follow [SemVer](https://semver.org/) versioning format.

Once the Pull Request containing the new code/version/release has been merged, run the following commands, where `vX.Y.Z` is the new/desired version release.

```bash
git checkout master
git pull
git tag -a vX.Y.Z  # For an annotated tag
git tag -m vX.Y.Z  # For a lightweight tag
git tag vX.Y.Z     # For a tag with no extra data
git push --tags
```

This will trigger Docker Hub to build an image with the SemVer version as a tag.

See the following documentation for information on tagging:

- <https://git-scm.com/book/en/v2/Git-Basics-Tagging>
- <https://dev.to/neshaz/a-tutorial-for-tagging-releases-in-git-147e>

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="http://www.imperial.ac.uk/people/tim.greaves"><img src="https://avatars2.githubusercontent.com/u/7603619?v=4" width="100px;" alt=""/><br /><sub><b>Tim Greaves</b></sub></a><br /><a href="https://github.com/alan-turing-institute/binderhub-deploy/issues?q=author%3Atmbgreaves" title="Bug reports">🐛</a> <a href="https://github.com/alan-turing-institute/binderhub-deploy/commits?author=tmbgreaves" title="Code">💻</a> <a href="#ideas-tmbgreaves" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-tmbgreaves" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#platform-tmbgreaves" title="Packaging/porting to new platform">📦</a> <a href="#tool-tmbgreaves" title="Tools">🔧</a></td>
    <td align="center"><a href="https://uk.linkedin.com/in/gerardgorman"><img src="https://avatars1.githubusercontent.com/u/5394691?v=4" width="100px;" alt=""/><br /><sub><b>Gerard Gorman</b></sub></a><br /><a href="#ideas-ggorman" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/alan-turing-institute/binderhub-deploy/pulls?q=is%3Apr+reviewed-by%3Aggorman" title="Reviewed Pull Requests">👀</a></td>
    <td align="center"><a href="https://trallard.dev"><img src="https://avatars3.githubusercontent.com/u/23552331?v=4" width="100px;" alt=""/><br /><sub><b>Tania Allard</b></sub></a><br /><a href="https://github.com/alan-turing-institute/binderhub-deploy/issues?q=author%3Atrallard" title="Bug reports">🐛</a> <a href="https://github.com/alan-turing-institute/binderhub-deploy/commits?author=trallard" title="Code">💻</a> <a href="#ideas-trallard" title="Ideas, Planning, & Feedback">🤔</a> <a href="#tutorial-trallard" title="Tutorials">✅</a> <a href="#question-trallard" title="Answering Questions">💬</a></td>
    <td align="center"><a href="https://www.imperial.ac.uk/admin-services/ict/self-service/research-support/rcs/research-software-engineering/"><img src="https://avatars1.githubusercontent.com/u/6095790?v=4" width="100px;" alt=""/><br /><sub><b>Diego</b></sub></a><br /><a href="https://github.com/alan-turing-institute/binderhub-deploy/issues?q=author%3Adalonsoa" title="Bug reports">🐛</a> <a href="#ideas-dalonsoa" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/alan-turing-institute/binderhub-deploy/pulls?q=is%3Apr+reviewed-by%3Adalonsoa" title="Reviewed Pull Requests">👀</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

- Tim Greaves ([@tmbgreaves](https://github.com/tmbgreaves))
- Gerard Gorman ([@ggorman](https://github.com/ggorman))
- Tania Allard ([@trallard](https://github.com/trallard))
- Diego Alonso Alvarez ([@dalonsoa](https://github.com/dalonsoa))
