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
  echo '  git-rebase-sequence-creator [-hs] [-f TICKET,TICKET] [-e TICKET,TICKET] -t PROJ_CODE -t TYPE -c START_REF'
  printf "    %-20s %s\n" '-t PROJ_CODE' 'The Jira project code.'
  printf "    %-20s %s\n" '-c START_REF' 'The starting Git reference.'
  printf "    %-20s %s\n" '-t TYPE' 'The release type. One of UAT or LIVE.'
  printf "    %-20s %s\n" '-e' 'A comma separated list of tickets to force exclusion of regardless of status.'
  printf "    %-20s %s\n" '-f' 'A comma separated list of tickets to force inclusion of regardless of status.'
  printf "    %-20s %s\n" '-s' 'Strip color from output.'
  printf "    %-20s %s\n" '-h' 'Display this help message.'
}

while getopts "sht:c:p:f:e:" opt; do
  case "${opt}" in
    h)
      usage
      exit 0
      ;;
    s) STRIP_COLORS=1 ;;
    t) RELEASE_TYPE="${OPTARG}" ;;
    c) START_COMMIT="${OPTARG}" ;;
    p) PROJECT_CODE="${OPTARG}" ;;
    e) EXCLUDED_TICKETS="${OPTARG}" ;;
    f) FORCED_TICKETS="${OPTARG}" ;;
    :)
      echo "Invalid option: ${OPTARG} requires an argument" 1>&2
      usage
      exit 1
      ;;
  esac
done

shift "$(($OPTIND - 1))"

. "${SCRIPT_DIR}/colors.sh" ${STRIP_COLORS:-0}

err() {
  echo "${COLOR_FG_RED}Error:${COLOR_RESET} ${1}" 1>&2
}

header() {
  echo
  echo "${COLOR_FG_YELLOW}${1}${COLOR_RESET}"
  echo
}

continue() {
  echo
  read -p "Continue? [Yn] " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo
    err 'Aborted.'
    exit 1
  fi
  echo
}

tolower() {
  echo "$@" | tr '[:upper:]' '[:lower:]'
}

get_statuses() {
  "${SCRIPT_DIR}/git-jira-status.sh" -rs "${1}" "${2}" 2> /dev/null
}

get_status_regex() {
  local PIPED_EXCLUSIONS
  local STATUS_REGEX
  local AWK_REGEX

  # Combine our list so we can use it as part of a regex.
  printf -v PIPED_EXCLUSIONS '%s|' "$@"
  printf -v STATUS_REGEX '(%s)\)$' "${PIPED_EXCLUSIONS%?}"
  printf -v AWK_REGEX '!/(%s)/' "${STATUS_REGEX}"

  echo "${AWK_REGEX}"
}

case_insensitive_awk() {
  echo "${2}" | awk "{original=\$0;\$0=tolower(\$0)} ${1} {print original}"
}

exclude_tickets() {
  local EXCLUDED_TICKETS
  local AWK_REGEX

  EXCLUDED_TICKETS="${2}"

  if [ ! -z "${EXCLUDED_TICKETS}" ]; then
    printf -v AWK_REGEX '!/(%s)/' $(tolower "${EXCLUDED_TICKETS}" | tr ',' '|')

    case_insensitive_awk "${AWK_REGEX}" "${1}"
  else
    echo "${1}"
  fi
}

filter_statuses() {
  local AWK_REGEX
  local FORCED_TICKETS

  AWK_REGEX=$(tolower "${2}")
  FORCED_TICKETS="${3}"

  if [ ! -z "${FORCED_TICKETS}" ]; then
    printf -v AWK_REGEX '%s || /(%s)/' "${AWK_REGEX}" $(tolower "${FORCED_TICKETS}" | tr ',' '|')
  fi

  case_insensitive_awk "${AWK_REGEX}" "${1}"
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
EXCLUDED_STATUSES+=('Discovery')
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
echo
echo 'Tickets with these statuses will be removed:'
printf '  %s\n' "${EXCLUDED_STATUSES[@]}"

if [ ! -z "${EXCLUDED_TICKETS}" ]; then
  echo
  echo "These tickets will be ${COLOR_BOLD}excluded${COLOR_RESET} no matter what:"
  echo "  ${EXCLUDED_TICKETS}"
fi

if [ ! -z "${FORCED_TICKETS}" ]; then
  echo
  echo "These tickets will be ${COLOR_BOLD}included${COLOR_RESET} no matter what:"
  echo "  ${FORCED_TICKETS}"
fi

header 'Checking Jira statuses (this can take a while).'

FILTERED_COMMITS=$(filter_statuses \
  "$(get_statuses "${PROJECT_CODE}" "${START_COMMIT}")" \
  "$(get_status_regex "${EXCLUDED_STATUSES[@]}")" \
  "${FORCED_TICKETS:-}")

FILTERED_COMMITS=$(exclude_tickets "${FILTERED_COMMITS}" "${EXCLUDED_TICKETS:-}")

header 'Filtered list.'

if [ -z "${FILTERED_COMMITS}" ]; then
  err 'No allowed commits. Check your starting commit and release type.'
  exit 1
fi

echo "${FILTERED_COMMITS}"
continue
echo "${FILTERED_COMMITS}" | awk '{print "pick " $0}' > "${SEQUENCE_FILE}"
echo

exit 0
