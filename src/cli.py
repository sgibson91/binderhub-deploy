import sys
import argparse
from initialise import construct_config

DESCRIPTION = (
    "binderhub-deploy: A command line tool to automatically deploy a BinderHub"
    " to Azure Cloud."
)


def parse_args(args):
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    subparsers = parser.add_subparsers(help="Available binderhub-deploy sub-commands")

    parser_init = subparsers.add_parser(
        "init", help="Initialise a config.json file to describe the deployment",
    )
    parser_init.set_defaults(func=construct_config)

    parser_setup = subparsers.add_parser(
        "setup", help="Install the required tools for deployment",
    )

    parser_deploy = subparsers.add_parser(
        "deploy", help="Deploy the BinderHub to Azure from config.json",
    )

    parser_logs = subparsers.add_parser(
        "logs", help="Print the log output of the BinderHub",
    )

    parser_info = subparsers.add_parser(
        "info", help="Print the IP addresses of the BinderHub and JupyterHub",
    )

    parser_upgrade = subparsers.add_parser(
        "upgrade", help="Upgrade the BinderHub helm chart",
    )

    parser_teardown = subparsers.add_parser(
        "teardown", help="Destroy the BinderHub deployment",
    )

    return parser.parse_args()


def main():
    args = parse_args(sys.argv[1:])
    print(vars(args))


if __name__ == "__main__":
    main()
