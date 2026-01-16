#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

ACCENT_COLOR="${THEME[blue]}"
SECONDARY_COLOR="${THEME[background]}"
BG_COLOR="${THEME[background]}"
BG_BAR="${THEME[bblack]}"  # Changed to Grey
TIME_COLOR="${THEME[foreground]}"

if [[ $1 =~ ^[[:digit:]]+$ ]]; then
  MAX_TITLE_WIDTH=20
else
  MAX_TITLE_WIDTH=$(($(tmux display -p '#{window_width}' 2>/dev/null || echo 120) - 130))
fi

MAX_TITLE_WIDTH=25

if cmus-remote -Q >/dev/null 2>/dev/null; then
  CMUS_STATUS=$(cmus-remote -Q)
  STATUS=$(echo "$CMUS_STATUS" | grep status | head -n 1 | cut -d' ' -f2-)
  TITLE=$(echo "$CMUS_STATUS" | grep 'tag title' | cut -d' ' -f3-)
  DURATION=$(echo "$CMUS_STATUS" | grep 'duration' | cut -d' ' -f2-)
  POSITION=$(echo "$CMUS_STATUS" | grep 'position' | cut -d' ' -f2-)

  P_MIN=$(printf '%02d' $((POSITION / 60)))
  P_SEC=$(printf '%02d' $((POSITION % 60)))
  D_MIN=$(printf '%02d' $((DURATION / 60)))
  D_SEC=$(printf '%02d' $((DURATION % 60)))
  TIME="[$P_MIN:$P_SEC / $D_MIN:$D_SEC]"

  if [ "$D_SEC" = "-1" ]; then
    TIME="[ $P_MIN:$P_SEC]"
  fi

  if [ -n "$TITLE" ]; then
    if [ "$STATUS" = "playing" ]; then
      PLAY_STATE="  $OUTPUT"
    else
      PLAY_STATE="  $OUTPUT"
    fi
    OUTPUT="$PLAY_STATE $TITLE"
  else
    OUTPUT=''
  fi
fi

if [ "${#OUTPUT}" -ge $MAX_TITLE_WIDTH ]; then
  OUTPUT="$PLAY_STATE ${TITLE:0:$MAX_TITLE_WIDTH-1}"
  OUTPUT="${OUTPUT%"${OUTPUT##*[![:space:]]}"}…"
fi

if [ -z "$OUTPUT" ]; then
  echo ""
else
  OUT=" $OUTPUT $TIME "
  ONLY_OUT=" $OUTPUT "
  TIME_INDEX=${#ONLY_OUT}
  OUTPUT_LENGTH=${#OUT}
  PERCENT=$((POSITION * 100 / DURATION))
  PROGRESS=$((OUTPUT_LENGTH * PERCENT / 100))
  O=" $OUTPUT"

  # === BUBBLE LOGIC ===
  if [ $PROGRESS -gt 0 ]; then
     L_CAP="#[fg=$ACCENT_COLOR,bg=${THEME[background]}]"
  else
     L_CAP="#[fg=$BG_BAR,bg=${THEME[background]}]"
  fi
  R_CAP="#[fg=$BG_BAR,bg=${THEME[background]}]"

  if [ $PROGRESS -le $TIME_INDEX ]; then
    echo "${L_CAP}#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:PROGRESS}#[fg=$ACCENT_COLOR,bg=$BG_BAR]${O:PROGRESS:TIME_INDEX}#[fg=$TIME_COLOR,bg=$BG_BAR]$TIME${R_CAP} "
  else
    DIFF=$((PROGRESS - TIME_INDEX))
    echo "${L_CAP}#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:TIME_INDEX}#[fg=$BG_BAR,bg=$ACCENT_COLOR]${OUT:TIME_INDEX:DIFF}#[fg=$TIME_COLOR,bg=$BG_BAR]${OUT:PROGRESS}${R_CAP} "
  fi
fi
