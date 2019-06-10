# Automatically deploy a BinderHub to Microsoft Azure

![mit_license_badge](https://img.shields.io/badge/License-MIT-yellow.svg)

[BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) is a cloud-based, multi-server technology used for hosting repoducible computing environments and interactive Jupyter Notebooks built from code repositories.

This repo contains a set of scripts to automatically deploy a BinderHub onto [Microsoft Azure](https://azure.microsoft.com/en-gb/), and connect a [DockerHub](https://hub.docker.com/) container registry, so that you can host your own [Binder](https://mybinder.readthedocs.io/en/latest/) service.

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
- [Customising your BinderHub Deployment](#customising-your-binderhub-deployment)
- [Contributors](#contributors)

---

## Usage

This repo can either be run locally or as "Platform as a Service" through the "Deploy to Azure" button in the ["Deploy to Azure" Button](#deploy-to-azure-button) section.

To use these scripts locally, clone this repo and change into the directory.

```
git clone https://github.com/alan-turing-institute/binderhub-deploy.git
cd binderhub-deploy
```

To make the scripts executable and then run them, do the following:

```
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

* For a list of available data centre regions, [see here](https://azure.microsoft.com/en-us/global-infrastructure/locations/).
  This should be a _region_ and **not** a _location_, for example "West Europe" or "Central US".
  These can be equivalently written as `westeurope` and `centralus`, respectively.
* For a list of available Linux Virtual Machines, [see here](https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/sizes-general).
  This should be something like, for example `Standard_D2s_v3`.
* The versions of the BinderHub Helm Chart can be found [here](https://jupyterhub.github.io/helm-chart/#development-releases-binderhub) and are of the form `0.2.0-<commit-hash>`.
  It is advised to select the most recent version unless you specifically require an older one.

```
{
  "azure": {
    "subscription": "",   // Azure subscription name or ID (a hex-string)
    "res_grp_name": "",   // Azure Resource Group name
    "location": "",       // Azure Data Centre region
    "node_count": 1,      // Number of nodes to deploy. 3 is preferrable for a stable cluster, but may be liable to caps.
    "vm_size": "",        // Azure virtual machine type to deploy
    "sp_app_id": null,    // Azure service principal ID (optional)
    "sp_app_key": null,   // Azure service principal password (optional)
    "sp_tenant_id": null  // Azure tenant ID (optional)
  },
  "binderhub": {
    "name": "",           // Name of your BinderHub
    "version": "",        // Helm chart version to deploy, should be 0.2.0-<commit-hash>
    "contact_email": ""   // Email for letsencrypt https certificate. CANNOT be left blank.
  },
  "docker": {
    "username": null,     // Docker username (can be supplied at runtime)
    "password": null,     // Docker password (can be supplied at runtime)
    "org": null,          // A DockerHub organisation to push images to (optional)
    "image_prefix": ""    // The prefix to preprend to Docker images (e.g. "binder-prod")
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

### `setup.sh`

This script checks whether the required command line tools are already installed.
If any are missing, the script uses the system package manager or [`curl`](https://curl.haxx.se/docs/) to install the command line interfaces (CLIs).
The CLIs to be installed are:

* [Microsoft Azure (`azure-cli`)](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes (`kubectl`)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl)
* [Helm (`helm`)](https://helm.sh/docs/using_helm/#from-script)

Any dependencies that are not automatically installed by these packages will also be installed.

### `deploy.sh`

This script reads in values from `config.json` and deploys a Kubernetes cluster.
It then creates `config.yaml` and `secret.yaml` files, respectively, using [`config-template.yaml`](./config-template.yaml) and [`secret-template.yaml`](./secret-template.yaml).

The script will ask for your Docker ID and password if you haven't supplied them in the config file.
The ID is your Docker username, **NOT** the associated email.
If you have provided a Docker organisation in `config.json`, then Docker ID **MUST** be a member of this organisation.

Both a JupyterHub and BinderHub are installed via a Helm Chart onto the deployed Kubernetes cluster and the `config.yaml` file is updated with the JupyterHub IP address.
The BinderHub is then linked to the provided DockerHub account to store the created images.

`config.yaml` and `secret.yaml` are both git-ignored so that secrets cannot be pushed back to GitHub.

The script also outputs log files (`<file-name>.log`) for each stage of the deployment.
These files are also git-ignored.

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

You will be asked to provide a [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals) in the form launched when you click the "Deploy to Azure" button above.

[**NOTE:** The following instructions can also be run in a local terminal session.
They will require the Azure command line to be installed, so make sure to run [`setup.sh`](./setup.sh) first.]

To create a Service Principal, go to the [Azure Portal](https://portal.azure.com/) (and login!) and open the Cloud Shell:

![Open Shell in Azure](images/open_shell_in_azure.png)

You may be asked to create storage when you open the shell.
This is expected, click "Create".

Make sure the shell is set to Bash, not PowerShell.

![Bash Shell](images/bash_shell.png)

Set the subscription you'd like to deploy your BinderHub on.

```
az account set -s <subscription>
```

This image shows the command being executed for an "Azure Pass - Sponsorship" subscription.

![Set Subscription](images/set_subscription.png)

You will need the subscription ID, which you can retrieve by running:

```
az account list --refresh --output table
```

![List Subscriptions](images/az_account_list.png)

Next, create the Service Principal with the following command.
Make sure to give it a sensible name!

```
az ad sp create-for-rbac --name binderhub-sp --role contributor --scopes /subscriptions/<subscription ID from above>
```

![Create Service PRincipal](images/create-for-rbac.png)

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
```
  az storage blob download-batch --account-name <ACCOUNT_NAME> --source <BLOB_NAME> --pattern "*" -d "<OUTPUT_DIRECTORY>"
```

The `--pattern` argument can be used to fetch particular files, for example all log files:
```
  az storage blob download-batch --account-name <ACCOUNT_NAME> --source <BLOB_NAME> --pattern "*.log" -d "<OUTPUT_DIRECTORY>"
```

To fetch a single file, specify `REMOTE_FILENAME` for the name of the file in blob storage, and `LOCAL_FILENAME` for the filename it will be fetched into:
```
  az storage blob download --account-name <ACCOUNT_NAME> --container-name <BLOB_NAME> --name <REMOTE_FILENAME> --file <LOCAL_FILENAME>
```

For full documentation, see the [`az storage blob` documentation](https://docs.microsoft.com/en-us/cli/azure/storage/blob?view=azure-cli-latest).

### Accessing your BinderHub after Deployment

Once the deployment has succeeded and you've downloaded the log files, visit the IP address of your Binder page to test it's working.

The Binder IP address can be found by running the following:
```
cat <OUTPUT_DIRECTORY>/binder-ip.log
```

A good repository to test your BinderHub with is [binder-examples/requirements](https://github.com/binder-examples/requirements)

## Customising your BinderHub Deployment

Customising your BinderHub deployment is as simple as editing `config.yaml` and/or `secret.yaml` and then upgrading the BinderHub Helm Chart.
The Helm Chart can be upgraded by running [`upgrade.sh`](./upgrade.sh) (make sure you have the CLIs installed by running [`setup.sh`](./setup.sh) first).

The Jupyter guide to customising the underlying JupyterHub can be found [here](https://zero-to-jupyterhub.readthedocs.io/en/latest/extending-jupyterhub.html).

The BinderHub guide for changing the landing page logo can be found [here](https://binderhub.readthedocs.io/en/latest/customizing.html#template-customization).

## Contributors

We would like to acknowledge and thank the following people for their contributions to this project:

* Tim Greaves ([@tmbgreaves](https://github.com/tmbgreaves))
* Gerard Gorman ([@ggorman](https://github.com/ggorman))
* Tania Allard ([@trallard](https://github.com/trallard))
* Diego Alonso Alvarez ([@dalonsoa](https://github.com/dalonsoa))
