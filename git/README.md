The scripts in this repository are able to be executed by directly calling them 
`./git-overlap.sh` or calling them with git `git overlap.sh`. The wrapper 
scripts in this folder enable calling them through git without the `.sh` 
extension.

Assuming the repository has been added to your path, the following are the same:

```sh
git-release-notes.sh develop~5 develop
git release-notes.sh develop~5 develop
git release-notes develop~5 develop
```
