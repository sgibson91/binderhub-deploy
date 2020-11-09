import json
import argparse


# Read in new version number
parser = argparse.ArgumentParser()
parser.add_argument("version")
parser.add_argument("--dry-run", action="store_true")
args = parser.parse_args()

# Read in Azure ARM template
azure_arm_template_path = "../azure.deploy.json"
with open(azure_arm_template_path) as stream:
    config = json.load(stream)

# Update ARM template with new version
config["parameters"]["setupDockerImage"]["defaultValue"] = f"sgibson91/binderhub-setup:{args.version.strip('v')}"
config["parameters"]["setupDockerImage"]["allowedValues"] = [f"sgibson91/binderhub-setup:{args.version.strip('v')}"] + config["parameters"]["setupDockerImage"]["allowedValues"]

if not args.dry_run:
    # Write updated ARM template
    json.dump(config, azure_arm_template_path, indent=2)
