# Code Management Scripts

This is a collection of scripts I use while reviewing and managing code.
They are primarily cenetered around code deployments and streamlining that
process.

## Installation

1. Clone the repository locally
2. If you want to use the scripts directly, add the `bin` folder to your `$PATH`.
3. If you want to use the git integration, add the `git` folder to your `$PATH`.

## Checking Jira status of tickets

Gets the Jira status of tickets pulled from Git logs. This requires installation
and configuration of the [Jira CLI](https://github.com/foxythemes/jira-cli).

```
$ git log --oneline develop~4..develop
5f393e3 (develop) EXAM-5678: This is an example commit message.
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message.
5a1c5b5 This is a message that doesn't follow the pattern.

$ git jira-status EXAM develop~4 develop
Parses git logs for messages that match the pattern "PROJ-1234: Lorem ipsum..."
It adds the JIRA status for these tickets to the output.

Showing logs from develop~4 to develop.
Looking for messages matching EXAM-1234.

5f393e3 (develop) EXAM-5678: This is an example commit message (EXAM-5678 : UAT Release Queue).
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message (EXAM-1234 : In Progress).
5a1c5b5 This is a message that doesn't follow the pattern.
```

Grabbing tickets for use in a `git rebase`.

```
$ git jira-status EXAM develop~4 develop | tail -r | egrep -iv '(Reopened|In Progress|QA|Ready for QA|Code review)'
5f393e3 (develop) EXAM-5678: This is an example commit message (EXAM-5678 : UAT Release Queue).
```

## Checking overlap of git changes

Shows you which commits in a range have shared file modifications with one another.

e.g. A:foo,bar, B:foo, C:bar, D:fizzbuzz, E:fizzbuzz,foo

* B needs A
* C needs A
* D needs nothing
* E needs D, B, A

It was created to illustrate problems with developer workflow.

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
