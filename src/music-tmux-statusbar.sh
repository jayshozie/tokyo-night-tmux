#!/usr/bin/env bash

ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_music)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

ACCENT_COLOR="${THEME[blue]}"
SECONDARY_COLOR="${THEME[background]}"
BG_COLOR="${THEME[bblack]}"
BG_BAR="${THEME[bblack]}"
TIME_COLOR="${THEME[blue]}"

if [[ $1 =~ ^[[:digit:]]+$ ]]; then
  MAX_TITLE_WIDTH=$1
else
  MAX_TITLE_WIDTH=$(($(tmux display -p '#{window_width}' 2>/dev/null || echo 120) - 90))
fi

# playerctl
if command -v playerctl >/dev/null; then
  PLAYER_STATUS=$(playerctl -a metadata --format "{{status}};{{mpris:length}};{{position}};{{title}};{{playerName}}" | grep -m1 "Playing")
  STATUS="playing"

  if [ -z "$PLAYER_STATUS" ]; then
    PLAYER_STATUS=$(playerctl -a metadata --format "{{status}};{{mpris:length}};{{position}};{{title}};{{playerName}}" | grep -m1 "Paused")
    STATUS="paused"
  fi

  TITLE=$(echo "$PLAYER_STATUS" | cut -d';' --fields=4)
  DURATION=$(echo "$PLAYER_STATUS" | cut -d';' --fields=2)
  POSITION=$(echo "$PLAYER_STATUS" | cut -d';' --fields=3)

  DURATION=$((DURATION / 1000000))
  POSITION=$((POSITION / 1000000))

  if [ "$DURATION" -eq 0 ]; then
    DURATION=-1
    POSITION=0
  fi

# nowplaying-cli (macOS)
elif command -v nowplaying-cli >/dev/null && { [[ $OSTYPE != "darwin"* ]] || { [[ $OSTYPE == "darwin"* ]] && [ "$(sw_vers -productVersion | cut -d. -f1)" -lt 15 ]; }; }; then
  NPCLI_PROPERTIES=(title duration elapsedTime playbackRate isAlwaysLive)
  mapfile -t NPCLI_OUTPUT < <(nowplaying-cli get "${NPCLI_PROPERTIES[@]}")
  declare -A NPCLI_VALUES
  for ((i = 0; i < ${#NPCLI_PROPERTIES[@]}; i++)); do
    [ "${NPCLI_OUTPUT[$i]}" = "null" ] && NPCLI_OUTPUT[$i]=""
    NPCLI_VALUES[${NPCLI_PROPERTIES[$i]}]="${NPCLI_OUTPUT[$i]}"
  done
  if [ -n "${NPCLI_VALUES[playbackRate]}" ] && [ "${NPCLI_VALUES[playbackRate]}" -gt 0 ]; then
    STATUS="playing"
  else
    STATUS="paused"
  fi
  TITLE="${NPCLI_VALUES[title]}"
  if [ "${NPCLI_VALUES[isAlwaysLive]}" = "1" ]; then
    DURATION=-1
    POSITION=0
  else
    DURATION=$(printf "%.0f" "${NPCLI_VALUES[duration]}")
    POSITION=$(printf "%.0f" "${NPCLI_VALUES[elapsedTime]}")
  fi
fi

if [ -n "$DURATION" ] && [ -n "$POSITION" ] && [ "$DURATION" -gt 0 ] && [ "$DURATION" -lt 3600 ]; then
  TIME="[$(date -d@$POSITION -u +%M:%S) / $(date -d@$DURATION -u +%M:%S)]"
else
  TIME="[--:--]"
fi

if [ -n "$TITLE" ]; then
  if [ "$STATUS" = "playing" ]; then
    PLAY_STATE="  $OUTPUT"
  else
    PLAY_STATE=" 󰏤 $OUTPUT"
  fi
  OUTPUT="$PLAY_STATE $TITLE "

  if [ "${#OUTPUT}" -ge $MAX_TITLE_WIDTH ]; then
    OUTPUT="$PLAY_STATE ${TITLE:0:$MAX_TITLE_WIDTH-1}…"
  fi
else
  OUTPUT=''
fi

MAX_TITLE_WIDTH=25
if [ "${#OUTPUT}" -ge $MAX_TITLE_WIDTH ]; then
  OUTPUT="$PLAY_STATE ${TITLE:0:$MAX_TITLE_WIDTH-1}"
  OUTPUT="${OUTPUT%"${OUTPUT##*[![:space:]]}"}… "
fi

if [ -z "$OUTPUT" ]; then
  # Empty state
  echo ""
else
  OUT="$OUTPUT $TIME "
  ONLY_OUT="$OUTPUT "
  TIME_INDEX=${#ONLY_OUT}
  OUTPUT_LENGTH=${#OUT}
  PERCENT=$((POSITION * 100 / DURATION))
  PROGRESS=$((OUTPUT_LENGTH * PERCENT / 100))
  O="$OUTPUT"

  if [ $PROGRESS -gt 0 ]; then
     L_CAP="#[fg=$ACCENT_COLOR,bg=${THEME[background]}]"
  else
     L_CAP="#[fg=$BG_BAR,bg=${THEME[background]}]"
  fi

  R_CAP="#[fg=$BG_BAR,bg=${THEME[background]}]"

  if [ $PROGRESS -le $TIME_INDEX ]; then
    # Case 1: Progress is within the Title
    echo "${L_CAP}#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:PROGRESS}#[fg=$ACCENT_COLOR,bg=$BG_BAR]${O:PROGRESS:TIME_INDEX}#[fg=$TIME_COLOR,bg=$BG_BAR]$TIME${R_CAP} "
  else
    # Case 2: Progress covers Title and eats into Time
    DIFF=$((PROGRESS - TIME_INDEX))
    echo "${L_CAP}#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:TIME_INDEX}#[fg=$BG_BAR,bg=$ACCENT_COLOR]${OUT:TIME_INDEX:DIFF}#[fg=$TIME_COLOR,bg=$BG_BAR]${OUT:PROGRESS}${R_CAP} "
  fi
fi
