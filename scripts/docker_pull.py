import json
import docker
import requests


def get_request(url: str, header: dict = None, params: dict = None) -> dict:
    """Make a GET request to a URL. If the URL returns links, step through them
    and concatenate the responses. Return the JSON encoded response.

    Args:
        url (str): The URL to make the request against
        header (dict, optional): A dictionary of headers to send with the
                                 request. Defaults to None.
        params (dict, optional): A dictionary of parameters to send with the
                                 request. Defaults to None.

    Returns:
        dict: The response of the request
    """
    resp = requests.get(url, headers=header, params=params)

    if not resp:
        raise RuntimeError(f"Could not fetch response from: {url}")

    if resp.links:
        full_resp = resp.json()

        while "next" in resp.links.keys():
            resp = requests.get(
                resp.links["next"]["url"], headers=header, params=params
            )
            full_resp.extend(resp.json())

        return full_resp

    else:
        return resp.json()


def get_all_tags(owner: str, repo: str) -> list:
    """Fetch a list of tags from a GitHub repository using the GitHub REST API

    Args:
        owner (str): The owner of the repository
        repo (str): The name of the repository

    Returns:
        list: A list of all the tags within the repository
    """
    tags = ["latest"]
    url = f"https://api.github.com/repos/{owner}/{repo}/git/matching-refs/tags"
    out = get_request(url)

    for item in out:
        ref = item["ref"].split("/")[-1].strip("v")
        tags.append(ref)

    return tags


def pull_image(image_name: str, tag: str, client=docker.APIClient(base_url='unix://var/run/docker.sock')) -> None:
    """Pull a Docker image from Docker Hub

    Args:
        image_name (str): The image to be pulled
        tag (str): The image tag to be pulled
    """
    for line in client.pull(image_name, tag=tag, stream=True, decode=True):
        print(json.dumps(line, indent=2, sort_keys=True))


def main():
    """Main function"""
    tags = get_all_tags("alan-turing-institute", "binderhub-deploy")

    for tag in tags:
        pull_image("sgibson91/binderhub-setup", tag)


if __name__ == "__main__":
    main()
