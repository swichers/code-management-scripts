#!/usr/bin/env bash
#
# Parses through git history and prints the ticket status (if found).
#
# Requires JIRA CLI to be installed: https://github.com/foxythemes/jira-cli
#
# Usage:
#  git-jira-status.sh project_code start_ref end_ref
#
# Example:
#  git-jira-status.sh EXAM 2.4.2 HEAD

# shellcheck source=/dev/null
. "$(git --exec-path)/git-sh-setup"

set -euo pipefail

# shellcheck disable=SC2034
USAGE="[-hrs] PROJ_CODE START_REF END_REF"

REVERSE_OUTPUT=0
STRIP_COLORS=0
SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})

while getopts ":hrs" opt; do
  case ${opt} in
    r)
      REVERSE_OUTPUT=1
      ;;
    s)
      STRIP_COLORS=1
      ;;

    h)
      echo 'Usage:'
      echo '  git jira-status [-hrs] PROJ_CODE START_REF END_REF'
      echo '    PROJ_CODE   The Jira project code.'
      echo '    START_REF   The starting Git reference.'
      echo '    END_REF     The ending Git reference.'
      echo '    -h          Display this help message.'
      echo '    -r          Reverse Git log output.'
      echo '    -s          Strip color from output.'
      exit 0
      ;;
    \?)
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

PROJ_TOKEN=$(echo -n "${1-}" | tr '[:lower:]' '[:upper:]')
START_REF="${2-}"
END_REF="${3-HEAD}"

readonly REVERSE_OUTPUT
readonly STRIP_COLORS
readonly USAGE
readonly PROJ_TOKEN
readonly START_REF
readonly END_REF

jira_colorize_status() {
  local jira_status
  jira_status=$(echo -n "$*" | tr '[:upper:]' '[:lower:]')
  case $jira_status in
    new | discovery | 'story approval')
      echo -n "${COLOR_FG_RED}$*${COLOR_RESET}"
      ;;
    reopened | ready | 'in progress')
      echo -n "${COLOR_FG_MAGENTA}$*${COLOR_RESET}"
      ;;
    'ready for review' | 'code review' | 'ready for qa' | qa)
      echo -n "${COLOR_FG_CYAN}$*${COLOR_RESET}"
      ;;
    'uat release queue')
      echo -n "${COLOR_BOLD}${COLOR_FG_YELLOW}$*${COLOR_RESET}"
      ;;
    'ready for uat' | uat)
      echo -n "${COLOR_FG_BLUE}$*${COLOR_RESET}"
      ;;
    'prod release queue' | 'done')
      echo -n "${COLOR_BOLD}${COLOR_FG_GREEN}$*${COLOR_RESET}"
      ;;
    *)
      echo -n "$*"
      ;;
  esac
}

require_jira_cli() {
  if ! command -v jira > /dev/null; then
    echo 'You must install the jira-cli to use this.' >&2
    echo >&2
    echo 'https://github.com/foxythemes/jira-cli' >&2
    return 1
  fi

  return 0
}

require_project_token() {
  if [ -z "${1-}" ]; then
    echo 'Must be given a project token to match against (case insensitive).' >&2
    echo >&2
    usage
    return 1
  fi

  return 0
}

require_git_refs() {
  if [ -z "${1-}" ] || [ -z "${2-}" ]; then
    echo 'Must be given a start ref and end ref.' >&2
    echo >&2
    usage
    return 1
  fi

  return 0
}

show_intro() {
  echo 'Parses git logs for messages that match the pattern "PROJ-1234: Lorem ipsum..."' >&2
  echo 'It adds the JIRA status for these tickets to the output.' >&2
  echo  >&2
  echo "Showing logs from ${COLOR_FG_YELLOW}${2}${COLOR_RESET} to ${COLOR_FG_YELLOW}${3}${COLOR_RESET}." >&2
  echo "Looking for messages matching ${COLOR_BOLD}${1}${COLOR_RESET}-1234." >&2
  echo  >&2

  return 0
}

jira_get_issue_from_log() {
  local jira_id

  # Normalize the log message.
  jira_id=$(echo -n "${2}" | tr '[:lower:]' '[:upper:]')
  # Ensure it matches our EXAM 1234 or EXAM-1234 pattern.
  jira_id=$(echo -n "${jira_id}" | awk "toupper(\$0) ~ /^${1}[ -][0-9]+/{print \$0}")
  # Convert EXAM 1234 to EXAM-1234 and filter out EXAM-0.
  jira_id=$(echo -n "${jira_id}" | sed -E -e "s/^${1}[ -]([0-9]+).+/${1}-\1/" -e "s/^${1}-[0]+//")

  echo -n "${jira_id}"
}

jira_get_issue_status() {
  local jira_status
  local jira_id
  local ticket_summary

  jira_id="${1}"
  ticket_summary=$(jira i "${jira_id}")

  jira_status=$(echo -n "${ticket_summary}" |
    sed -E -e "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" -e '/^[ ]*Status/!d' |
    awk -F '[[:space:]][[:space:]]+' '//{print $3}')
  echo -n "${jira_status}"
}

print_log_item() {
  local original_line
  local ref
  local log_line
  local jira_id
  local jira_status

  original_line="${2}"
  ref=${original_line:0:8}
  log_line=${original_line:9}
  jira_status=''
  jira_id=$(jira_get_issue_from_log "${1}" "${log_line}")

  if [ "${jira_id}" ]; then
    jira_status=$(jira_get_issue_status "${jira_id}")
    echo "${COLOR_FG_YELLOW}${ref}${COLOR_RESET} ${log_line} (${COLOR_BOLD}${COLOR_FG_YELLOW}${jira_id}${COLOR_RESET} : $(jira_colorize_status "${jira_status}"))"
  else
    echo "${COLOR_FG_YELLOW}${ref}${COLOR_RESET} ${COLOR_FG_RED}${log_line}${COLOR_RESET}"
  fi
}

_main() {
  . "${SCRIPT_DIR}/colors.sh" ${STRIP_COLORS}
  require_jira_cli
  require_work_tree
  require_project_token "${PROJ_TOKEN}"
  require_git_refs "${START_REF}" "${END_REF}"
  show_intro "${PROJ_TOKEN}" "${START_REF}" "${END_REF}"

  git_commits=$(git log --pretty='format:%h %s' --abbrev=8 "${START_REF}".."${END_REF}")

  if [ $REVERSE_OUTPUT -eq 1 ]; then
    git_commits=$(echo "${git_commits}" | tail -r)
  fi

  while read -r LINE; do
    print_log_item "${PROJ_TOKEN}" "${LINE}"
  done <<< "${git_commits}"
}

_main

exit 0
