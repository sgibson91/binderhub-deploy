# binderhub-deploy

A set of scripts to automatically deploy a [BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) onto [Microsoft Azure](https://azure.microsoft.com/en-gb/).

**List of scripts:**
* [**setup.sh**](#setup)
* [**deploy.sh**](#deploy)
* [**info.sh**](#info)

## Usage

Update `config.json` with the appropriate values. It takes the following format.

```json
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
    "id": "",            # DockerHub ID
    "org": null,         # The DockerHub organisation id belongs to (if necessary)
    "image_prefix": ""   # The prefix to preprend to Binder images (e.g. "binder-dev")
  },
  "secretFile": null     # Path to file containing DockerHub password (script will look for ~/.secret/BinderHub.json if left as null)
}
```

A `~/.secret` folder should also be created containing a `BinderHub.json` file with the following config.

```json
{
  "password": "<dockerhub-password>"  # DockerHub password to match id in config.json
}
```

---

<a name="setup"></a>
### setup.sh

This script uses [`curl`](https://curl.haxx.se/docs/) to install command line interfaces (CLIs) for Microsoft Azure (`azure-cli`), Kubernetes (`kubectl`) and Helm (`helm`).

Command line install scripts were found in the following documentation:
* [Azure-CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes-CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl) (macOS version)
* [Helm-CLI](https://helm.sh/docs/using_helm/#from-script)

The script reads in `config.json` (via `read_config.py`) in order to acquire Azure variables.

<a name="deploy"></a>
### deploy.sh

This script reads in `config.json` using `read_config.py`, then creates `config.yaml` and `secret.yaml` files via `create_config.py` and `create_secret.py` respectively (using `config-template.yaml` and `secret-template.yaml`).
Both a JupyterHub and BinderHub are installed and the `config.yaml` file is updated with the JupyterHub IP address.

<a name="info"></a>
### info.sh

The script will print the IP addresses of both the JupyterHub and the BinderHub to the terminal.
It reads the BinderHub name from `config.json` using `read_config.py`.
