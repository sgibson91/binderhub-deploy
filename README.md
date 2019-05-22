# Automatically deploy a BinderHub to Microsoft Azure

[BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) is a cloud-based, multi-server technology used for hosting repoducible computing environments and interactive Jupyter Notebooks.

This repo contains a set of scripts to automatically deploy a BinderHub onto [Microsoft Azure](https://azure.microsoft.com/en-gb/) and connect a [DockerHub](https://hub.docker.com/) container registry.

This repo is based on the following set of deployment scripts for Google Cloud: [nicain/binder-deploy](https://github.com/nicain/binder-deploy)

**List of scripts:**
* [**setup.sh**](#setupsh)
* [**deploy.sh**](#deploysh)
* [**logs.sh**](#logssh)
* [**info.sh**](#infosh)
* [**teardown.sh**](#teardownsh)

## Usage

To use these scripts locally, clone this repo and change into the directory.

```
git clone https://github.com/alan-turing-institute/binderhub-deploy.git
cd binderhub-deploy
```

The Python files `create_config.py` and `create_secret.py` require Python version >= 3.6, but no extra packages are needed.

To make the scripts executable and then run them, do the following:

```
chmod 700 <script-name>.sh
./<script-name>.sh
```

To deploy, you should run `setup.sh` first, then `deploy.sh`.
You can run `logs.sh` and `info.sh` to get the JupyterHub logs and IP addresses respectively.
`teardown.sh` should only be used to remove your BinderHub deployment.

Create a file called `config.json` which has the following format.
Fill the quotation marks with your desired namespaces, etc.
(Note that `#` tokens won't be permitted in the actual JSON file.)

* For a list of available locations, [see here](https://azure.microsoft.com/en-us/global-infrastructure/locations/).
* For a list of available Linux Virtual Machines, [see here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/).
* The `cluster_name` must be 63 characters or less and only contain lower case alphanumeric characters or a hyphen (-).

```
{
  "azure": {
    "subscription": "",  # Azure subscription name
    "res_grp_name": "",  # Azure Resource Group name
    "location": "",      # Azure Data Centre location
    "cluster_name": "",  # Kubernetes cluster name
    "node_count": "",    # Number of nodes to deploy
    "vm_size": ""        # Azure virtual machine type to deploy
  },
  "binderhub": {
    "name": "",          # Name of you BinderHub
    "version": ""        # Helm chart version to deploy
  },
  "docker": {
    "org": null,         # The DockerHub organisation id belongs to (if necessary)
    "image_prefix": ""   # The prefix to preprend to Binder images (e.g. "binder-dev")
  }
}
```

You can copy [`template-config.json`](template-config.json) should you require.

---

### setup.sh

This script checks whether the required command line programs are already installed, and if any are missing uses the system package manager or [`curl`](https://curl.haxx.se/docs/) to install command line interfaces (CLIs) for Microsoft Azure (`azure-cli`), Kubernetes (`kubectl`), Helm (`helm`), and the ssh key generator (ssh-keygen), along with dependencies that are not automatically installed by those packages.

Command line install scripts were found in the following documentation:
* [Azure-CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes-CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl) (macOS version)
* [Helm-CLI](https://helm.sh/docs/using_helm/#from-script)

### deploy.sh

This script reads in values from `config.json`, deploys a Kubernetes cluster, then creates `config.yaml` and `secret.yaml` files via `create_config.py` and `create_secret.py` respectively (using `config-template.yaml` and `secret-template.yaml`).
The script will ask for your Docker ID and password.
The ID is your Docker username, NOT the email.
If you have provided a Docker organisation in `config.json`, then Docker ID **MUST** be a member of this organisation.
Both a JupyterHub and BinderHub are installed onto the deployed Kubernetes cluster and the `config.yaml` file is updated with the JupyterHub IP address.

### logs.sh

This script will print the JupyterHub logs to the terminal for debugging.
It reads from `config.json` in order to get the BinderHub name.
It then finds the pod the JupyterHub is deployed on and calls the logs.

### info.sh

The script will print the IP addresses of both the JupyterHub and the BinderHub to the terminal.
It reads the BinderHub name from `config.json`.

### teardown.sh

This script will purge the Helm release, delete the Kubernetes namespace and then delete the Azure Resource Group containing the computational resources.
The user should check the [Azure Portal](https://portal.azure.com/#home) to verify the resources have been deleted.

## Contributors

We would like to acknowledge and thank the following people for their contributions:

* Tim Greaves (@tmbgreaves)
* Gerard Gorman (@ggorman)
* Tania Allard (@trallard)
