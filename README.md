# Code Management Scripts

This is a collection of scripts I use while reviewing and building deployments.
They are primarily cenetered around code deployments and streamlining that
process.

## Installation

Clone the repository locally, and add the folder to your `$PATH`. To add
the git-enabled commands to git ensure that the git folder is accessible to your
`$PATH` as well.

## Checking Jira status of tickets

Gets the Jira status of tickets pulled from Git logs. This requires installation and configuration of the [Jira CLI](https://github.com/foxythemes/jira-cli).

```
$ git log --oneline develop~4..develop
5f393e3 (develop) EXAM-5678: This is an example commit message.
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message.
5a1c5b5 This is a message that doesn't follow the pattern.

$ git jira-status EXAM develop~4 develop
5f393e3 (develop) EXAM-5678: This is an example commit message (EXAM-5678 : UAT Release Queue).
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message (EXAM-1234 : In Progress).
5a1c5b5 This is a message that doesn't follow the pattern.
```

## Checking overlap of git changes

Compares two reference points and identfies overlapping file changes.

```
$ git overlap develop feature/EXAM-168
Checking the following commits for overlapping changes:

  b3a8609 dd435bc 2ebb38c 4544c63 8ba083a 8d0b26e e31ce4f


Parent b3a8609 -> dd435bc 2ebb38c 4544c63 8ba083a 8d0b26e e31ce4f

  b3a8609 shares changes with dd435bc 2ebb38c 4544c63 8ba083a 8d0b26e e31ce4f

    EXAM-168: Remove forced overrides in Varnish.
    EXAM-168: Add varnish purge for local dev.
    EXAM-168: Add request policy overrides for JSONAPI.
<...snip...>
```

## Generating simple release notes

Generates simple release notes based on the git history.

```
$ git log --oneline develop~4..develop
5f393e3 (develop) EXAM-5678: This is an example commit message.
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message.
5a1c5b5 This is a message that doesn't follow the pattern.

$ git release-notes develop~4 develop
* EXAM-1234: This is another example message.
* EXAM-5678: This is an example commit message.
* This is a message that doesn't follow the pattern.
```
