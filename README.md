# binderhub-deploy

A set of scripts to automatically deploy a [BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) onto [Microsoft Azure](https://azure.microsoft.com/en-gb/).

**List of scripts:**
* [**setup.py**](#setup)

---

<a name="setup"></a>
### setup.py

This script uses [`curl`](https://curl.haxx.se/docs/) to install command line interfaces (CLIs) for Microsoft Azure (`azure-cli`), Kubernetes (`kubectl`) and Helm (`helm`).

Command line install scripts were found in the following documentation:
* [Azure-CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes-CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl) (macOS version)
* [Helm-CLI](https://helm.sh/docs/using_helm/#from-script)

The script also reads in `config.json` which is of the following format.

```json
{
  "subscription": "",  # Azure subscription name
  "res_grp_name": "",  # Azure Resource Group name
  "location": "",      # Azure Data Centre location
  "cluster_name": "",  # Kubernetes cluster name
  "node_count": "",    # Number of nodes to deploy
  "vm_size": ""        # Azure virtual machine type to deploy
}
```
