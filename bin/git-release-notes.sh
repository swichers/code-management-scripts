#!/usr/bin/env bash
#
# Prints out simple markdown formatted release notes.
#
# Usage:
#   git-release-notes.sh start_ref end_ref
#
# Example:
#  git-release-notes.sh develop release/2.4.2

. "$(git --exec-path)/git-sh-setup"

set -euo pipefail

require_work_tree

# shellcheck disable=SC2034
USAGE="START_REF END_REF"
if [[ -z "${1-}" ]] || [[ -z "${2-}" ]]; then
  usage
fi

git log --pretty='format:%s' "${1}".."${2}" | \
  grep -Ev '^Merge (remote-tracking branch|branch|pull request)' | \
  sort -ufds | \
  sed 's/^/* /'
