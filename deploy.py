import json
import subprocess
import argparse


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--apiToken", required=True,
                        help="apiToken: output from openssl rand -hex 32")
    parser.add_argument("--secretToken", required=True,
                        help="secretToken: output from openssl rand -hex 32")

    return parser.parse_args()


def get_config():
    file = "config.json"
    return json.load(open(file, "r"))


def main():
    args = parse_args()

    # Get config
    config = get_config()

    # Install the Helm Chart using the configuration files, to deploy both a
    # BinderHub and a JupyterHub:
    if not (config["docker"]["docker_org"] is None):
        cmd = (
            f'python create_config.py -id={config["docker"]["docker_id"]} '
            f'--prefix={config["docker"]["image_prefix"]} -org={config["docker"]["docker_org"]} '
            f'--force'
        )
    else:
        cmd = (
            f'python create_config.py -id={config["docker"]["docker_id"]} '
            f'--prefix={config["docker"]["image_prefix"]} --force'
        )
    subprocess.run(cmd.split())

    cmd = (
        f'python create_secret.py --apiToken={args.apiToken} --secretToken={args.secretToken} '
        f'--secretFile={config["secretFile"]} --force'
    )
    subprocess.run(cmd.split())

    cmd = (
        f'helm install jupyterhub/binderhub --version={config["binderhub"]["version"]} '
        f'--name={config["binderhub"]["name"]} --namespace={config["binderhub"]["name"]} '
        f'-f secret.yaml -f config.yaml'
    )
    subprocess.run(cmd.split())

    return (config["binderhub"]["name"], config["docker_id"], config["image_prefix"],
            config["docker_org"], config["binderhub"]["version"])


if __name__ == "__main__":
    binderhub_name = main()
    print(binderhub_name)
