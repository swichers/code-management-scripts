[![Codacy Badge](https://app.codacy.com/project/badge/Grade/90ae654e782f4665a030938f1960d20e)](https://www.codacy.com/manual/swichers/code-management-scripts?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=swichers/code-management-scripts&amp;utm_campaign=Badge_Grade)

# Code Management Scripts

This repository features a number of scripts for streamlining code releases and
 auditing. These are especially useful if you base your releases on Jira
 tickets. See the [docs](docs) folder for more information and see the
 [bin](bin) folder for available scripts.

## Functionality provided

* Create simple release notes
* View git history with Jira status
* Check file relationship between chains of commits

## Requirements

* git
* [Jira CLI](https://github.com/foxythemes/jira-cli)

The scripts are best utilized by calling them through git, though they can
 technically be called directly. Jira CLI is a requirement when using the Jira
 related scripts.

## Installation

Copy this repository locally. It's recommended to use git in order to make
 updating easier.

```sh
git clone git@github.com:swichers/code-management-scripts.git
```

Add the scripts directory to your path. For example, in `~/.zshrc` you would add
 the following code:

```sh
export PATH=path/to/code-management-scripts/git:$PATH
```
