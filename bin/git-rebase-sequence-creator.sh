#!/usr/bin/env bash
#
# Build a git rebase sequence file for sending to a git rebase job.
#
# Builds the file based on Jira ticket status.
#
# Example:
#  git-rebase-sequence-creator.sh -t EXAM -t LIVE -c abc123
#  GIT_SEQUENCE_EDITOR="${SCRIPT_DIR}/git-rebase-sequence-creator.sh \
#    -p ${PROJECT_CODE} \
#    -t ${RELEASE_TYPE} \
#    -c ${START_COMMIT}" \
#    git rebase "${START_COMMIT}" -i

set -euo pipefail

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
SEQUENCE_FILE=${@: -1}

usage() {
  echo 'Usage:'
  echo '  git-rebase-sequence-creator [-hs] -t PROJ_CODE -t TYPE -c START_REF'
  printf "    %-20s %s\n" 'PROJ_CODE' 'The Jira project code.'
  printf "    %-20s %s\n" 'START_REF' 'The starting Git reference.'
  printf "    %-20s %s\n" 'TYPE' 'The release type. One of UAT or LIVE.'
  printf "    %-20s %s\n" '-s' 'Strip color from output.'
  printf "    %-20s %s\n" '-h' 'Display this help message.'
}

while [ "${1:-}" != "" ]; do
  case $1 in
    -s | --strip-colors)
      STRIP_COLORS=1
      ;;
    -t | --release-type)
      shift
      RELEASE_TYPE=$1
      ;;
    -c | --commit)
      shift
      START_COMMIT=$1
      ;;
    -p | --project)
      shift
      PROJECT_CODE=$1
      ;;

    -h | --help)
      usage
      exit 0
      ;;

  esac
  shift
done

. "${SCRIPT_DIR}/colors.sh" ${STRIP_COLORS:-0}

err() {
  echo "${COLOR_FG_RED}Error:${COLOR_RESET} ${1}" 1>&2
}

header() {
  echo
  echo "${COLOR_FG_YELLOW}${1}${COLOR_RESET}"
  echo
}

if [[ "${RELEASE_TYPE:-}" != 'UAT' && "${RELEASE_TYPE:-}" != 'LIVE' ]]; then
  err "Release type must be one of: UAT, LIVE."
  usage
  exit 1
elif ! git rev-parse --verify --quiet "${START_COMMIT:-}" > /dev/null; then
  err "Start commit ${START_COMMIT:-} does not exist."
  usage
  exit 1
elif [ -z "${PROJECT_CODE:-}" ]; then
  err "A project code must be supplied."
  usage
  exit 1
fi

# TODO: Need to make this configurable out of script.
EXCLUDED_STATUSES=()
EXCLUDED_STATUSES+=('Code Review')
EXCLUDED_STATUSES+=('In Progress')
EXCLUDED_STATUSES+=('New')
EXCLUDED_STATUSES+=('QA')
EXCLUDED_STATUSES+=('Ready for QA')
EXCLUDED_STATUSES+=('Ready for Review')
EXCLUDED_STATUSES+=('Ready')
EXCLUDED_STATUSES+=('Reopened')
EXCLUDED_STATUSES+=('Story Approval')

if [[ "${RELEASE_TYPE}" == 'LIVE' ]]; then
  EXCLUDED_STATUSES+=('Ready for UAT')
  EXCLUDED_STATUSES+=('UAT Release Queue')
  EXCLUDED_STATUSES+=('UAT')
fi

header 'Filtering statuses.'
echo "Filtering for release of type ${COLOR_BOLD}${RELEASE_TYPE}${COLOR_RESET}."
echo 'Tickets with these statuses will be removed:'
printf '  %s\n' "${EXCLUDED_STATUSES[@]}"

header 'Checking Jira statuses (this can take a while).'

# Combine our list so we can use it as part of a regex.
printf -v GREP_EXCLUSIONS '%s|' "${EXCLUDED_STATUSES[@]}"
printf -v GREP_REGEX '(%s)\)$' "${GREP_EXCLUSIONS%?}"

FILTERED_COMMITS=$("${SCRIPT_DIR}/git-jira-status.sh" -rs "${PROJECT_CODE}" "${START_COMMIT}" 2> /dev/null | { egrep -vi "${GREP_REGEX}" || test $? = 1; })

header 'Filtered list.'
printf '%s\n' "${FILTERED_COMMITS:-}"

if [ -z "${FILTERED_COMMITS}" ]; then
  err 'No filtered commits. Check your starting commit and release type.'
  exit 1
fi

read -p "Continue? [Yn] " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo
  err 'Aborted.'
  exit 1
fi

echo "${FILTERED_COMMITS:-noop}" | sed -e 's/^/pick /' > "${SEQUENCE_FILE}"
echo

exit 0
