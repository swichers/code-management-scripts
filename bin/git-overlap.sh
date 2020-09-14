#!/usr/bin/env bash
#
# Checks the configured commit range to determine which commits modify files
# that were modified in an earlier commit.
#
# Example:
#  Commit 1:
#    foo.txt
#    bar.txt
#  Commit 2:
#    bar.txt
#  Commit 3:
#   foo.txt
#  Commit 4:
#    foobar.txt
#
# Commit 2 will be considered dependent on Commit 1.
# Commit 3 will be considered dependent on Commit 1, but not 2.
# Commit 4 will not be considered to have any dependencies.
#
# This is a very shallow check which does not account for functional or thematic
# dependencies. It should be considered a starting point for further
# investigation.
#
# Usage:
#  git-overlap.sh start_commit end_commit
#
# Example:
#  git-overlap.sh develop feature/my-new-feature

. "$(git --exec-path)/git-sh-setup"

set -euo pipefail

COLOR_BOLD=$(tput bold)
COLOR_RESET=$(tput sgr0)

COLOR_FG_YELLOW=$(tput setaf 3)

readonly COLOR_BOLD
readonly COLOR_RESET
readonly COLOR_FG_YELLOW

require_work_tree

# shellcheck disable=SC2034
USAGE="START_REF END_REF"
if [[ -z "${1-}" ]] || [[ -z "${2-}" ]]; then
  usage
fi

declare -a COMMITS=($(git log --pretty='format:%h' "${1}".."${2}"))

declare -i LEN="${#COMMITS[@]}"

indent() { sed 's/^/  /'; }

compare_commit_files() {
  local PARENT_FILES=$(git show --name-only "${1}" | tail -r | awk '1;/^$/{exit}' | awk 'NF' | sort)
  local CHILD_FILES=$(git show --name-only "${2}" | tail -r | awk '1;/^$/{exit}' | awk 'NF' | sort)
  local MODIFIED=$(comm -12 <(echo "${PARENT_FILES}") <(echo "${CHILD_FILES}"))
  [[ "${MODIFIED}" ]]
}

echo "Checking the following commits for overlapping changes:"
echo
echo "${COMMITS[@]}" | indent
echo
echo

for ((index = 0; index < (LEN - 1); index++)); do
  declare -a DEPENDS_ON=()
  CURRENT="${COMMITS[$index]}"

  echo -n "Parent ${COLOR_BOLD}${COLOR_FG_YELLOW}${CURRENT}${COLOR_RESET} -> "

  for ((child_index = (index + 1); child_index < LEN; child_index++)); do
    CURRENT_CHILD="${COMMITS[$child_index]}"
    echo -n "${CURRENT_CHILD} "

    set +e
    compare_commit_files "${CURRENT}" "${CURRENT_CHILD}"
    if [[ $? -eq 1 ]]; then
      DEPENDS_ON+=("${CURRENT_CHILD}")
    fi
    set -e
  done

  echo

  if [[ ${#DEPENDS_ON[@]} -gt 0 ]]; then
    echo
    echo "${COLOR_BOLD}${CURRENT} shares changes with ${DEPENDS_ON[@]}${COLOR_RESET}" | indent
    echo
    for depend in "${DEPENDS_ON[@]}"; do
      git log --format=%B -n 1 "${depend}" | awk 'NF' | indent | indent
    done
    echo
  fi
done

exit 0
