# Contributing Guidelines

:space_invader: :tada: Thank you for contributing to the project! :tada: :space_invader:

The following is a set of guidelines for contributing to `binderhub-deploy` on GitHub.
These are mostly guidelines, not rules.
Use your best judgement and feel free to propose changes to this document in a Pull Request.

**Table of Contents**

- [:purple_heart: Code of Conduct](#purple_heart-code-of-conduct)
- [:question: What should I know before I get started?](#question-what-should-i-know-before-i-get-started)
  - [:package: `binderhub-deploy`](#package-binderhub-deploy)
  - [:open_file_folder: Scripts](#open_file_folder-scripts)
  - [:whale: Dockerfile](#whale-dockerfile)
  - [:rocket: Deploy to Azure button](#rocket-deploy-to-azure-button)
- [:gift: How can I contribute?](#gift-how-can-i-contribute)
  - [:bug: Reporting Bugs](#bug-reporting-bugs)
  - [:sparkles: Requesting Features](#sparkles-requesting-features)
  - [:hatching_chick: Your First Contribution](#hatching_chick-your-first-contribution)
  - [:arrow_right: Pull Requests](#arrow_right-pull-requests)
  - [:busts_in_silhouette: Acknowledging Contributors](#busts_in_silhouette-acknowledging-contributors)
- [:art: Styleguides](#art-styleguides)
  - [:heavy_dollar_sign: Bash Styleguide](#heavy_dollar_sign-bash-styleguide)
  - [:pencil: Markdown Styleguide](#pencil-markdown-styleguide)
- [:notebook: Additional Notes](#notebook-additional-notes)
  - [:label: Issue and Pull Request Labels](#label-issue-and-pull-request-labels)

---

## :purple_heart: Code of Conduct

This project and everyone participating in it is expected to abide by and uphold the [Code of Conduct](CODE_OF_CONDUCT.md).
Please report any unacceptable behaviour to [drsarahlgibson@gmail.com](mailto:drsarahlgibson@gmail.com).

## :question: What should I know before I get started?

### :package: `binderhub-deploy`

`binderhub-deploy` is a package designed to automatically deploy a [BinderHub](https://binderhub.readthedocs.io) to [Azure](https://azure.microsoft.com/en-gb/).

BinderHub is a cloud-based, multi-server platform for sharing reproducible computational environments using a [Jupyter](https://jupyter.org) interface.
[@sgibson91](https://github.com/sgibson91) has given [many talks](https://sgibson91.github.io/speaking) one what Binder/BinderHub/[mybinder.org](https://mybinder.org) is and how it works.
This repository is recommended for those who wish to automate the deployment of their own, private BinderHubs.

### :open_file_folder: Scripts

This tool is based on bash scripts, information about which can be found in the [Usage](README.md#children_crossing-usage) section of the [README](README.md).

### :whale: Dockerfile

This repository contains a [Dockerfile](Dockerfile) that can be built to run the tool.
It also serves as a back-end to the "Deploy to Azure" button.

The built image of this file is hosted at: [hub.docker.com/repository/docker/sgibson91/binderhub-setup](https://hub.docker.com/repository/docker/sgibson91/binderhub-setup).
The `master` branch is automatically built and tagged as `latest` whereas [GitHub releases and tags](https://github.com/alan-turing-institute/binderhub-deploy/releases) are given the matching image tag.

When running the image, the parameters defined in [`template-config.json`](template-config.json) would be passed as [environment variables](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file).

### :rocket: Deploy to Azure button

The Deploy to Azure button serves as a graphical user interface to the Docker image that passes information as environment variables at runtime.
The configuration of the button parameters and variables is stored in the [`azure.deploy.json`](azure.deploy.json) file.

## :gift: How can I contribute?

### :bug: Reporting Bugs

If something doesn't work the way you expect it to, please check it hasn't already been reported in the repository's [issue tracker](https://github.com/alan-turing-institute/binderhub-deploy/issues).
Bug reports should have the [bug label](https://github.com/alan-turing-institute/binderhub-deploy/issues?q=is%3Aissue+is%3Aopen+label%3Abug), or have a title beginning with [`[BUG]`](https://github.com/alan-turing-institute/binderhub-deploy/issues?q=is%3Aissue+is%3Aopen+%5BBUG%5D).

If you can't find an issue already reporting your bug, then please feel free to [open a new issue](https://github.com/alan-turing-institute/binderhub-deploy/issues/new?assignees=&labels=bug&template=bug_report.md&title=%5BBUG%5D).
This repository has a [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) to help you be as descriptive as possible so we can squash that bug! :muscle:

### :sparkles: Requesting Features

If there was something extra you wish `binderhub-deploy` could do, please check that the feature hasn't already been requested in the project's [issue tracker](https://github.com/alan-turing-institute/binderhub-deploy/issues).
Feature requests should have the [enhancement label](https://github.com/alan-turing-institute/binderhub-deploy/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement).
Please also check the [closed issues](https://github.com/alan-turing-institute/binderhub-deploy/issues?q=is%3Aissue+is%3Aclosed) to make sure the feature has not already been requested but the project maintainers decided against developing it.

If you find an open issue describing the feature you wish for, you can "+1" the issue by giving a thumbs up reaction on the **top comment of the issue**.
You may also leave any thoughts or offers for support as new comments on the issue.

If you don't find an issue describing your feature, please [open a feature request](https://github.com/alan-turing-institute/binderhub-deploy/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=).
This repository has a [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) to help you map out the feature you'd like.

### :hatching_chick: Your First Contribution

Unsure where to start contributing?
Check out the [good first issue](https://github.com/alan-turing-institute/binderhub-deploy/labels/good%20first%20issue) and [help wanted](https://github.com/alan-turing-institute/binderhub-deploy/labels/help%20wanted) labels to see where the project is looking for input.
Spelling corrections and clarifications to documentation are also always welcome!

### :arrow_right: Pull Requests

A Pull Request is a means for [people to collaboratively review and work on changes](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests) before they are introduced into the base branch of the code base.

To prepare your contribution for review, please follow these steps:

1. [Fork this repository](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Create a new branch](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-and-deleting-branches-within-your-repository) on your fork
   1. Where possible and appropriate, please use the following convention when naming your branch: `<type>/<issue-number>/<short-description>`.
      For example, if your contribution is fixing a a typo that was flagged in issue number 11, your branch name would be as follows: `fix/11/typo`.
3. Edit files or add new ones!
4. [Open your Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)
   1. This repository has a [pull request template](.github/PULL_REQUEST_TEMPLATE.md) which will help you summarise your contribution and help reviewers know where to focus their feedback.
      Please complete it where possible and appropriate.

Congratulations! :tada:
You are now a `binderhub-deploy` developer! :space_invader:

The project maintainers will then review your Pull Request and may ask for some changes.
Once you and the maintainers are happy, your contribution will be merged!

### :busts_in_silhouette: Acknowledging Contributors

This repository uses [all-contributors](https://allcontributors.org/) to acknowledge the time and expertise of the people who have made this tool into what it is today.
Specifically, all-contributors has an [emoji key](https://allcontributors.org/docs/en/emoji-key) to show the breadth of expertise required for a project like this.

## :art: Styleguides

### :heavy_dollar_sign: Bash Styleguide

This repository implements bash linting and formatting via [`shellcheck`](https://github.com/koalaman/shellcheck) and [`shfmt`](https://github.com/mvdan/sh).
These checks are run in a [GitHub Action](.github/workflows/shellcheck-master.yml) and will leave [comments on Pull Requests](.github/workflows/shellcheck-pr.yml) if issues are found.
This will help us maintain readable code for future contributors.

### :pencil: Markdown Styleguide

Documentation files are written in [Markdown](https://guides.github.com/features/mastering-markdown/).

When writing Markdown, it is recommended to start a new sentence on a new line and define a new paragraph by leaving a single blank line.
(Check out the raw version of this file for an example!)
While the sentences will render as a single paragraph; when suggestions are made on Pull Requests, the GitHub User Interface will only highlight the affected sentence - not the whole paragraph.
This makes reviews much easier to read!

## :notebook: Additional Notes

### :label: Issue and Pull Request Labels

Issues and Pull Requests can have labels assigned to them which indicate at a glance what aspects of the project they describe.
It is also possible to [sort issues by label](https://help.github.com/en/github/managing-your-work-on-github/filtering-issues-and-pull-requests-by-labels) making it easier to track down specific issues.
Below is a table with the currently used labels in the repository.

| Label | Description |
| :--- | :--- |
| [![azure-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/azure)](https://github.com/alan-turing-institute/binderhub-deploy/labels/azure) | Relating to the Azure deployment |
| [![bug-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/bug)](https://github.com/alan-turing-institute/binderhub-deploy/labels/bug) | Something isn't working |
| [![ci-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/ci)](https://github.com/alan-turing-institute/binderhub-deploy/labels/ci) | Relating to Continuous Integration workflows |
| [![docker-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/docker)](https://github.com/alan-turing-institute/binderhub-deploy/labels/docker) | Relating to the Dockerfile or image |
| [![docs-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/documentation)](https://github.com/alan-turing-institute/binderhub-deploy/labels/documentation) | Edits or improvements to the documentation |
| [![enhancement-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/enhancement)](https://github.com/alan-turing-institute/binderhub-deploy/labels/enhancement) | New feature or request |
| [![good-first-issue](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/good%20first%20issue)](https://github.com/alan-turing-institute/binderhub-deploy/labels/good%20first%20issue) | Good for newcomers |
| [![helm-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/helm)](https://github.com/alan-turing-institute/binderhub-deploy/labels/helm) | Relating to deploying Helm charts |
| [![help wanted](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/help%20wanted)](https://github.com/alan-turing-institute/binderhub-deploy/labels/help%20wanted) | Extra attention is needed |
| [![k8s-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/kubernetes)](https://github.com/alan-turing-institute/binderhub-deploy/labels/kubernetes) | Related to deploying Kubernetes |
| [![linux-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/linux)](https://github.com/alan-turing-institute/binderhub-deploy/labels/linux) | Related to running on Linux |
| [![management](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/management)](https://github.com/alan-turing-institute/binderhub-deploy/labels/management) | Related to managing the project |
| [![osx-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/osx)](https://github.com/alan-turing-institute/binderhub-deploy/labels/osx) | Related to running on MacOS |
| [![windows-label](https://img.shields.io/github/labels/alan-turing-institute/binderhub-deploy/windows)](https://github.com/alan-turing-institute/binderhub-deploy/labels/windows) | Related to running on Windows |
