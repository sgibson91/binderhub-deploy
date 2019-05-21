# binderhub-deploy

A set of scripts to automatically deploy a [BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) onto [Microsoft Azure](https://azure.microsoft.com/en-gb/).

**List of scripts:**
* [**deploy.sh**](#deploysh)

## Usage

Create a file called `config.json` which has the following format.
Fill the values with your desired namespaces, etc.
(Note that `#` tokens won't be permitted in the actual JSON file.)

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

---

### deploy.sh

This script reads in `config.json` using `read_config.py`, then creates `config.yaml` and `secret.yaml` files via `create_config.py` and `create_secret.py` respectively (using `config-template.yaml` and `secret-template.yaml`).
The script will ask for your Docker ID and password.
The ID is your Docker username, NOT the email.
If you have provided a Docker organisation in `config.json`, then Docker ID **MUST** be a member of this organisation.
Both a JupyterHub and BinderHub are installed and the `config.yaml` file is updated with the JupyterHub IP address.
