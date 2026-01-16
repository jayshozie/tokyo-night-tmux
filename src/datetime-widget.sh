#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_datetime 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

# Assign values based on user config
date_format=$(tmux show-option -gv @tokyo-night-tmux_date_format 2>/dev/null)
time_format=$(tmux show-option -gv @tokyo-night-tmux_time_format 2>/dev/null)

date_string=""
time_string=""

if [[ $date_format == "YMD" ]]; then
  date_string="%Y-%m-%d"
elif [[ $date_format == "MDY" ]]; then
  date_string="%m-%d-%Y"
elif [[ $date_format == "DMY" ]]; then
  date_string="%d-%m-%Y"
elif [[ $date_format == "hide" ]]; then
  date_string=""
else
  date_string="%Y-%m-%d"
fi

if [[ $time_format == "12H" ]]; then
  time_string="%I:%M %p"
elif [[ $time_format == "hide" ]]; then
  time_string=""
else
  time_string="%H:%M"
fi

separator=""
if [[ $date_string && $time_string ]]; then
  separator=" "
fi

date_string="$(date +"$date_string")"
time_string="$(date +"$time_string")"

echo "#[fg=${THEME[blue]},bg=${THEME[background]}]#[fg=${THEME[bblack]},bg=${THEME[blue]},bold]  $date_string $separator$time_string #[fg=${THEME[blue]},bg=${THEME[background]},nobold]"
