#!/usr/bin/env bash
#
# Eases creation of a release branch based on Jira ticket statuses.

SUBDIRECTORY_OK=Yes
USAGE="-t <type> -c <commit> -v <release version> -b <base branch>

Type should be one of UAT or LIVE.
Commit should be the starting commit for reviewing Jira status.
Release version should be the semantic version number for the release.
Base branch should be the starting branch."

. $(git --exec-path)/git-sh-setup

require_clean_work_tree create-release "There are changes that should be stashed before continuing."

set -euo pipefail

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
    -v | --release-version)
      shift
      RELEASE_VERSION=$1
      ;;
    -b | --branch)
      shift
      BASE_BRANCH=$1
      ;;
    -p | --project)
      shift
      PROJECT_CODE=$1
      ;;

    -h | --help)
      usage
      exit
      ;;

    *)
      usage
      exit 1
      ;;
  esac
  shift
done

RELEASE_BRANCH="release/${RELEASE_VERSION:-}"
SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})

. "${SCRIPT_DIR}/colors.sh" ${STRIP_COLORS:-0}

err() {
  echo "${COLOR_FG_RED}Error:${COLOR_RESET} ${1}" 1>&2
}

header() {
  echo
  echo "${COLOR_FG_YELLOW}${1}${COLOR_RESET}"
  echo
}

echo "${COLOR_BG_RED}${COLOR_FG_WHITE}${COLOR_BOLD}BETA${COLOR_RESET} ${COLOR_FG_YELLOW}Release branch creator. ${COLOR_BG_RED}${COLOR_FG_WHITE}${COLOR_BOLD}BETA${COLOR_RESET}"
echo

if [[ "${RELEASE_TYPE:-}" != 'UAT' && "${RELEASE_TYPE:-}" != 'LIVE' ]]; then
  err "Release type must be one of: UAT, LIVE."
  usage
  exit 1
elif ! git rev-parse --verify --quiet "${BASE_BRANCH:-}" > /dev/null; then
  err "Base branch ${BASE_BRANCH:-} does not exist."
  usage
  exit 1
elif git rev-parse --verify --quiet "${RELEASE_BRANCH:-}" > /dev/null; then
  err "Release branch ${RELEASE_BRANCH:-} already exists."
  usage
  exit 1
elif ! git rev-parse --verify --quiet "${START_COMMIT:-}" > /dev/null; then
  err "Start commit ${START_COMMIT:-} does not exist."
  usage
  exit 1
elif [ -z "${RELEASE_VERSION:-}" ]; then
  err "Release version must be provided."
  usage
  exit 1
elif [ -z "${PROJECT_CODE:-}" ]; then
  err "A project code must be supplied."
  usage
  exit 1
fi

header 'Creating the release branch.'

git checkout "${BASE_BRANCH}"
git checkout -b "${RELEASE_BRANCH}"

header 'Creating rebase sequence.'

GIT_SEQUENCE_EDITOR="${SCRIPT_DIR}/git-rebase-sequence-creator.sh -p ${PROJECT_CODE} -t ${RELEASE_TYPE} -c ${START_COMMIT}" git rebase "${START_COMMIT}" -i

exit 0
