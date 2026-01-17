#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_git)
[[ ${ENABLED} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/themes.sh"

cd "$1" || exit 1
# Redefine RESET to avoid forcing the default background, allowing it to stay
# inside the bubble
RESET="#[nobold,noitalics,nounderscore,nodim]"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
STATUS=$(git status --porcelain 2>/dev/null | grep -cE "^(M| M)")

SYNC_MODE=0
NEED_PUSH=0

if [[ ${#BRANCH} -gt 25 ]]; then
  BRANCH="${BRANCH:0:25}…"
fi

STATUS_CHANGED=""
STATUS_INSERTIONS=""
STATUS_DELETIONS=""
STATUS_UNTRACKED=""

if [[ $STATUS -ne 0 ]]; then
  DIFF_COUNTS=($(git diff --numstat 2>/dev/null | awk 'NF==3 {changed+=1; ins+=$1; del+=$2} END {printf("%d %d %d", changed, ins, del)}'))
  CHANGED_COUNT=${DIFF_COUNTS[0]}
  INSERTIONS_COUNT=${DIFF_COUNTS[1]}
  DELETIONS_COUNT=${DIFF_COUNTS[2]}

  SYNC_MODE=1
fi

UNTRACKED_COUNT="$(git ls-files --other --exclude-standard | wc -l | bc)"

# Stats remain floating so keep their original backgrounds
if [[ $CHANGED_COUNT -gt 0 ]]; then
  STATUS_CHANGED="#[fg=${THEME[yellow]},bg=${THEME[background]},bold]  ${CHANGED_COUNT}"
fi

if [[ $INSERTIONS_COUNT -gt 0 ]]; then
  STATUS_INSERTIONS="#[fg=${THEME[green]},bg=${THEME[background]},bold]  ${INSERTIONS_COUNT}"
fi

if [[ $DELETIONS_COUNT -gt 0 ]]; then
  STATUS_DELETIONS="#[fg=${THEME[red]},bg=${THEME[background]},bold]  ${DELETIONS_COUNT}"
fi

if [[ $UNTRACKED_COUNT -gt 0 ]]; then
  STATUS_UNTRACKED="#[fg=${THEME[black]},bg=${THEME[background]},bold]  ${UNTRACKED_COUNT}"
fi

# Determine repository sync status
if [[ $SYNC_MODE -eq 0 ]]; then
  NEED_PUSH=$(git log @{push}.. | wc -l | bc)
  if [[ $NEED_PUSH -gt 0 ]]; then
    SYNC_MODE=2
  else
    LAST_FETCH=$(stat -c %Y .git/FETCH_HEAD | bc)
    NOW=$(date +%s | bc)
    if [[ $((NOW - LAST_FETCH)) -gt 300 ]]; then
      git fetch --atomic origin --negotiation-tip=HEAD
    fi
    REMOTE_DIFF="$(git diff --numstat "${BRANCH}" "origin/${BRANCH}" 2>/dev/null)"
    if [[ -n $REMOTE_DIFF ]]; then
      SYNC_MODE=3
    fi
  fi
fi

case "$SYNC_MODE" in
1) REMOTE_STATUS="#[fg=${THEME[bred]},bold]󱓎" ;;
2) REMOTE_STATUS="#[fg=${THEME[red]},bold]󰛃" ;;
3) REMOTE_STATUS="#[fg=${THEME[magenta]},bold]󰛀" ;;
*) REMOTE_STATUS="#[fg=${THEME[green]},bold]" ;;
esac

if [[ -n $BRANCH ]]; then
  echo "#[fg=${THEME[bblack]},bg=${THEME[background]}]#[fg=${THEME[foreground]},bg=${THEME[bblack]}]${REMOTE_STATUS} $RESET#[fg=${THEME[foreground]},bg=${THEME[bblack]}]${BRANCH}#[fg=${THEME[bblack]},bg=${THEME[background]},nobold]$STATUS_CHANGED$STATUS_INSERTIONS$STATUS_DELETIONS$STATUS_UNTRACKED "
fi
