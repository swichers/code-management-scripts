# git-release-notes

Generates simple markdown formatted release notes based on git history. This is
 a "dumb" listing with minimal filtering. It will remove merge commit messages
 while sorting and cleaning up the output slightly.

## Usage

```sh
git release-notes START_COMMIT END_COMMIT
```

**START_COMMIT** The starting commit hash, branch, or tag to begin reviewing
 commits from. This can be any valid identifier, including things such as `HEAD`
 or `mybranch~15`.

**END_COMMIT** The ending commit hash, branch, or tag to stop reviewing commits
 from.

## Example

Without:

```sh
$ git log --oneline develop~4..develop
5f393e3 (develop) EXAM-5678: This is an example commit message.
c598933 Merge branch 'hotfix'
ed7d84c EXAM-1234: This is another example message.
5a1c5b5 This is a message that doesn't follow the pattern.
```

With:

```sh
$ git release-notes develop~4 develop
* EXAM-1234: This is another example message.
* EXAM-5678: This is an example commit message.
* This is a message that doesn't follow the pattern.
```
