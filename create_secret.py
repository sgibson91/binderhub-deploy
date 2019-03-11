import yaml
import argparse
import os
import json


def parse_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("-id", "--docker-id", type=str, required=True,
                        help="Docker ID")
    parser.add_argument('--apiToken', type=str, required=True,
                        help="API Token")
    parser.add_argument('--secretToken', type=str, required=True,
                        help="Secret Token")
    parser.add_argument('--template', type=str, default='secret-template.yaml',
                        help="Template secret file")
    parser.add_argument('--secretFile', type=str, default='BinderHub.json')
    parser.add_argument('--force', action='store_true',
                        help="Overwrite existing files")
    parser.add_argument('output_file', nargs='?', default='secret.yaml',
                        help="Output file to save secret config to")

    return parser.parse_args()


def main():

    args = parse_args()

    if os.path.exists(args.output_file):
        if args.force == True:
            os.remove(args.output_file)
        else:
            raise RuntimeError("Output file already exists: {}".format(
                args.output_file))

    template = yaml.load(open(args.template, 'r'))

    template['jupyterhub']['hub']['services']['binder']['apiToken'] = (
        "{}".format(args.apiToken)
    )
    template['jupyterhub']['proxy']['secretToken'] = (
        "{}".format(args.secretToken)
    )
    template['registry']['username'] = args.docker_id

    secretFile = json.load(open(os.path.expanduser(args.secretFile), 'r'))
    template['registry']['password'] = secretFile['password']

    yaml.dump(template, open(args.output_file, 'w'), default_flow_style=False)

    return None


if __name__ == "__main__":
    main()
