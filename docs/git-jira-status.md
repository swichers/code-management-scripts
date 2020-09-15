# git-jira-status

This script will parse Jira tickets from commit messages and display their Jira
status inline. This requires installation and configuration of the
[Jira CLI](https://github.com/foxythemes/jira-cli).

## Requirements

* [Jira CLI](https://github.com/foxythemes/jira-cli)

* Commit messages must be formatted in this specific way:
`EXAM-000: An example commit message.` where EXAM is the Jira project code.

## Usage

```sh
git jira-status [-hrs] PROJECT_CODE START_COMMIT END_COMMIT
```

**-h** Show help.

**-r** Reverse the log output. This is useful for creating a list of commits for
using in a `git rebase`.

**-s** Strip color codes from the output. This is useful for modifying the
output with something such as `grep` or `sed`.

**PROJECT_CODE** The Jira project code. This is the machine identifier used by
Jira when creating issue links. For example, if the project is
'Code Management Scripts', the identifier might be 'CMS'.

**START_COMMIT** The starting commit hash, branch, or tag to begin reviewing
commits from. This can be any valid identifier, including `HEAD` or
`mybranch~15`.

**END_COMMIT** The ending commit hash, branch, or tag to stop reviewing commits
from. This is optional and defaults to `HEAD`.

## Example

### Viewing history without status

```sh
$ git log --oneline develop~4..develop
5f393e3 EXAM-5678: This is an example commit message.
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message.
5a1c5b5 This is a message that doesn't follow the pattern.
```

### The same information with status

```sh
$ git jira-status EXAM develop~4 develop
Parses git logs for messages that match the pattern "PROJ-1234: Lorem ipsum..."
It adds the JIRA status for these tickets to the output.

Showing logs from develop~4 to develop.
Looking for messages matching EXAM-1234.

5f393e3 EXAM-5678: This is an example commit message (EXAM-5678 : UAT Release Queue).
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message (EXAM-1234 : In Progress)
5a1c5b5 This is a message that doesn't follow the pattern.
```

## Grabbing tickets for use in a `git rebase`

```sh
$ git jira-status -rs EXAM develop~4 develop | egrep -iv '(New|Reopened|In Progress|QA|Ready for QA|Code review)\)$'
5f393e3 (develop) EXAM-5678: This is an example commit message (EXAM-5678 : UAT Release Queue).
```

When filtering a list of tickets to use in a `git rebase` it is import to:

* Reverse the output using `-r` so that the list is in an order `git rebase`
expects.

`git log` is in newest-to-oldest order, but the sequence file from `git rebase`
expects commits in `oldest-to-newest` order. Using the reverse flag enables you
to use the output without having to manually reverse it.

* Strip colors using `-s` so that `grep`, `sed`, or any other tools work as
expected.

The color codes embedded in the output can cause text matching to fail in
unexpected ways. Stripping colors will ensure that `grep` and other utilities
work as expected.

* When using `grep` it can be better to use an exclusion-based filter instead of
an inclusion-based one.

An inclusion-based filter will cause any non-conforming commits to be missed, an
exclusion-based filter will include those in its output.

* When using `grep` it is important to match the end of a line with the
surrounding parens.

If the regex is too loose then you can include or exclude tickets by mistake
when the commit message contains the status within. For example, if the Jira
status you are trying to filter is "New" and you do not match parens and the
end of line you may improperly filter out commits with the word "New" in the
commit message.
