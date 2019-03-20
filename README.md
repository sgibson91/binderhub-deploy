# binderhub-deploy

A set of scripts to automatically deploy a [BinderHub](https://binderhub.readthedocs.io/en/latest/index.html) onto a [Microsoft Azure](https://azure.microsoft.com/en-gb/) [Kubernetes](https://kubernetes.io/) cluster.

**List of scripts:**
* [**setup.sh**](#setup)

## Usage

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
  }
}
```

Make the shell scripts executable with the following command.
```bash
chmod 700 <script-name>.sh
```

---

<a name="setup"></a>
### setup.sh

This script uses [`curl`](https://curl.haxx.se/docs/) to install command line interfaces (CLIs) for Microsoft Azure (`azure-cli`), Kubernetes (`kubectl`) and Helm (`helm`).
The script will ask you to enter a passphrase when the SSH keys are being generated - this can be left blank.

Command line install scripts were found in the following documentation:
* [Azure-CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest#install-or-update)
* [Kubernetes-CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl) (macOS version)
* [Helm-CLI](https://helm.sh/docs/using_helm/#from-script)
