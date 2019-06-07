"""
A script to automatically generate a BinderHub secrets file populated with
DockerHub login details. Arguments are:
* -id: DockerHub ID
* --apiToken: Output of openssl rand -hex 32 command
* --secretToken: Output of openssl rand -hex 32 command
* --template: A template for a secret.yaml file to populate
* --password: Docker Hub password
* --force: If secret.yaml already exists, overwrite it
* output_file: File to save the secret config to
"""

import argparse
import os
from pathlib import Path

import yaml

# find the root dier of this file
BASE_DIR = Path(__file__).resolve().parent


def parse_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("-id", "--docker-id", type=str, required=True, help="Docker ID")
    parser.add_argument("--apiToken", type=str, required=True, help="API Token")
    parser.add_argument("--secretToken", type=str, required=True, help="Secret Token")
    parser.add_argument(
        "--template",
        type=str,
        default="secret-template.yaml",
        help="Template secret file",
    )
    parser.add_argument(
        "--password", type=str, required=True, help="Docker Hub password for Docker ID"
    )
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    parser.add_argument(
        "output_file",
        nargs="?",
        default="secret.yaml",
        help="Output file to save secret config to",
    )

    return parser.parse_args()


def main():

    args = parse_args()

    if os.path.exists(args.output_file):
        if args.force == True:
            os.remove(args.output_file)
        else:
            raise RuntimeError(
                "Output file already exists: {}".format(args.output_file)
            )
    # recreating the path for readability
    template_path = BASE_DIR.joinpath(args.template)

    template = yaml.safe_load(open(template_path, "r"))

    template["jupyterhub"]["hub"]["services"]["binder"]["apiToken"] = "{}".format(
        args.apiToken
    )
    template["jupyterhub"]["proxy"]["secretToken"] = "{}".format(args.secretToken)
    template["registry"]["username"] = args.docker_id
    template["registry"]["password"] = args.password

    yaml.dump(template, open(args.output_file, "w"), default_flow_style=False)

    return None


if __name__ == "__main__":
    main()
