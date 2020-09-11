#!/usr/bin/env bash
#
# Initialize several color variables for use with other scripts.
#
# Usage:
#   . "$(dirname $0)/colors.sh"

set -euo pipefail

init_colors() {
  local DISABLE_COLORS=${1:-0}

  COLOR_BOLD=$(tput bold)
  COLOR_RESET=$(tput sgr0)

  COLOR_FG_BLACK=$(tput setaf 0)
  COLOR_FG_RED=$(tput setaf 1)
  COLOR_FG_GREEN=$(tput setaf 2)
  COLOR_FG_YELLOW=$(tput setaf 3)
  COLOR_FG_BLUE=$(tput setaf 4)
  COLOR_FG_MAGENTA=$(tput setaf 5)
  COLOR_FG_CYAN=$(tput setaf 6)
  COLOR_FG_WHITE=$(tput setaf 7)

  COLOR_BG_BLACK=$(tput setab 0)
  COLOR_BG_RED=$(tput setab 1)
  COLOR_BG_GREEN=$(tput setab 2)
  COLOR_BG_YELLOW=$(tput setab 3)
  COLOR_BG_BLUE=$(tput setab 4)
  COLOR_BG_MAGENTA=$(tput setab 5)
  COLOR_BG_CYAN=$(tput setab 6)
  COLOR_BG_WHITE=$(tput setab 7)

  if [ ${DISABLE_COLORS} -eq 1 ]; then
    COLOR_BOLD=''
    COLOR_RESET=''

    COLOR_FG_BLACK=''
    COLOR_FG_RED=''
    COLOR_FG_GREEN=''
    COLOR_FG_YELLOW=''
    COLOR_FG_BLUE=''
    COLOR_FG_MAGENTA=''
    COLOR_FG_CYAN=''
    COLOR_FG_WHITE=''

    COLOR_BG_BLACK=''
    COLOR_BG_RED=''
    COLOR_BG_GREEN=''
    COLOR_BG_YELLOW=''
    COLOR_BG_BLUE=''
    COLOR_BG_MAGENTA=''
    COLOR_BG_CYAN=''
    COLOR_BG_WHITE=''
  fi

  readonly COLOR_BOLD
  readonly COLOR_RESET

  readonly COLOR_FG_BLACK
  readonly COLOR_FG_RED
  readonly COLOR_FG_GREEN
  readonly COLOR_FG_YELLOW
  readonly COLOR_FG_BLUE
  readonly COLOR_FG_MAGENTA
  readonly COLOR_FG_CYAN
  readonly COLOR_FG_WHITE

  readonly COLOR_BG_BLACK
  readonly COLOR_BG_RED
  readonly COLOR_BG_GREEN
  readonly COLOR_BG_YELLOW
  readonly COLOR_BG_BLUE
  readonly COLOR_BG_MAGENTA
  readonly COLOR_BG_CYAN
  readonly COLOR_BG_WHITE
}

init_colors ${1:-0}
