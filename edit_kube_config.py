"""
Script to manipulate a kubectl configuration file
"""

import argparse
from kubeconfig import KubeConfig


def parse_args():
    parser = argparse.ArgumentParser(
        description="This script will manipulate your kubectl configuration file"
    )

    parser.add_argument(
        "-n", "--name", required=True,
        help="The name of the cluster you'd like to manipulate"
    )
    parser.add_argument(
        "-g", "--resource-group", required=True,
        help="The Azure resource group the cluster was deployed in"
    )
    parser.add_argument(
        "-f", "--file",
        help=("Path to the configuration file you'd like to manipulate." +
              "Default filepath: ~/.kube/config")
    )
    parser.add_argument(
        "--purge", action="store_true",
        help="Completely remove the named cluster from your config file"
    )

    return parser.parse_args()


def main():
    # Parse command line args
    args = parse_args()

    # Check if alternative filepath has been provided and load the config file
    if args.file:
        conf = KubeConfig(path=args.file)
    else:
        conf = KubeConfig()

    # Purge the named cluster from the config file
    if args.purge:

        userName = f"clusterUser_{args.resource_group}_{args.name}"

        conf.delete_cluster(args.name)
        conf.delete_context(args.name)
        conf.unset(f"users.{userName}")
    else:
        # Placeholder else statement
        # Incase more functionality needs to be added
        pass

    print(conf.view())


if __name__ == "__main__":
    main()
