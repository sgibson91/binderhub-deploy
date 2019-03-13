import os
import json
import subprocess


def get_config():
    file = "config.json"
    return json.load(open(file, "r"))


def main():
    # Get config file
    config = get_config()

    # Install Azure-CLI
    cmd = "curl -L https://aka.ms/InstallAzureCli"
    subprocess.run(cmd.split())

    # Install kubectl - Kubernetes-CLI
    cmd = "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
    subprocess.run(cmd.split())
    # Make the kubectl binary executable
    cmd = "chmod +x ./kubectl"
    subprocess.run(cmd.split())
    # Move the binary into your PATH
    cmd = "sudo mv ./kubectl /usr/local/bin/kubectl"
    subprocess.run(cmd.split())

    # Install Helm cli - fetch install script and execute it locally
    cmd = "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh"
    subprocess.run(cmd.split())

    cmd = "chmod 700 get_helm.sh"
    subprocess.run(cmd.split())

    cmd = "./get_helm.sh"
    subprocess.run(cmd.split())

    # Login to Azure
    cmd = "az login --output table"
    subprocess.run(cmd.split())

    # Activate chosen subscription
    cmd = f'az account set -s "{config["subscription"]}"'
    subprocess.run(cmd.split())

    # Create a Resource Group
    cmd = (
        f'az group create --name {config["res_grp_name"]} --location {config["location"]} --output table'
    )
    subprocess.run(cmd.split())

    # Make a folder for the cluster
    os.mkdir(config['cluster_name'])
    os.chdir(config['cluster_name'])

    # Create an SSH key
    cmd = f'ssh-keygen -f ssh-key-{config["cluster_name"]}'
    subprocess.run(cmd.split())

    # Create an AKS cluster
    cmd = (
        f'az aks create --name {config["cluster_name"]} --resource-group {config["res_grp_name"]} '
        f'--ssh-key-value ssh-key-{config["cluster_name"]}.pub --node-count {config["node_count"]} '
        f'--node-vm-size {config["vm_size"]} --output table'
    )
    subprocess.run(cmd.split())

    # Get kubectl credentials from Azure
    cmd = (
        f'az aks get-credentials --name {config["cluster_name"]} --resource-group {config["res_grp_name"]} '
        f'--output table'
    )
    subprocess.run(cmd.split())

    # Check node is functional
    # TODO: Get above command to only print out the status and wait until status is ready before continuing
    cmd = "kubectl get node"
    subprocess.run(cmd.split())

    # Setup ServiceAccount for tiller
    cmd = "kubectl --namespace kube-system create serviceaccount tiller"
    subprocess.run(cmd.split())

    # Give the ServiceAccount full permissions to manage the cluster
    cmd = "kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller"
    subprocess.run(cmd.split())

    # Initialise helm and tiller
    cmd = "helm init --service-account tiller --wait"
    subprocess.run(cmd.split())

    # Secure tiller against attacks from within the cluster
    tiller_patch = '[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
    cmd = (
        f"kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='{tiller_patch}'"
    )
    subprocess.run(cmd.split())

    # Check helm has been configured correctly
    print("Verify Client and Server are running the same version number:")
    cmd = "helm version"
    subprocess.run(cmd.split())

    return None


if __name__ == "__main__":
    main()
