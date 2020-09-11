# git-create-release

This will filter commits from one branch into another based on their Jira issue status, provided that the commit message follows the appropriate format.

**Important:** This script relies on Jira statuses that will be unique to your Jira implementation. It is currently hard coded to a fixed list of statuses and will need to be adjusted to your Jira implementation. See the [git-rebase-sequence-creator](../bin/git-rebase-sequence-creator.sh) script.

## Requirements

* [Jira CLI](https://github.com/foxythemes/jira-cli)
* Commit messages must be formatted in this specific way: `EXAM-000: An example commit message.` where EXAM is the Jira project code.

## Usage

```sh
git create-release [-hs] -p PROJECT_CODE -b BASE_BRANCH -t RELEASE_TYPE -c START_COMMIT -v RELEASE_VERSION
```

**-h** Show help.

**-s** Strip color codes from the output. This is useful for modifying the output with something such as `grep` or `sed`.

**-p** The Jira project code. This is the machine identifier used by Jira when creating issue links. For example, if the project is 'Code Management Scripts', the identifier might be 'CMS'.

**-b** The branch to base the release from. This branch will serve as the source for commits to make it into the release branch. It will not be modified.

**-t** The release type. One of UAT or LIVE.

**-c** The starting commit hash, branch, or tag to begin reviewing commits from. This can be any valid identifier, including things such as `HEAD` or `mybranch~15`.

**-v** The semantic release version, such as 1.20.3. This will be used to construct the final release branch, such as `release/1.20.3`

