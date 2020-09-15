# git-overlap

Checks the provided commit range to determine which commits modify the same
files that are also modified in earlier commits. This is a shallow check which
does not account for functional or thematic dependencies. It is a starting point
for further investigation.

e.g.
* Commit 1
  * foo.txt
  * bar.txt
* Commit 2
  * bar.txt
* Commit 3
  * foo.txt
* Commit 4
  * foobar.txt

Commit 2 is considered dependent on Commit 1.

Commit 3 is considered dependent on Commit 1, but not 2.

Commit 4 is not considered to have any dependencies.

## Usage

```sh
git overlap START_COMMIT END_COMMIT
```

**START_COMMIT** The starting commit hash, branch, or tag to begin reviewing
commits from. This can be any valid identifier, including `HEAD` or
`mybranch~15`.

**END_COMMIT** The ending commit hash, branch, or tag to stop reviewing commits
from.

## Example

```sh
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
