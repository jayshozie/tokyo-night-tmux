#!/usr/bin/env bash

SELECTED_THEME="$(tmux show-option -gv @tokyo-night-tmux_theme)"
TRANSPARENT_THEME="$(tmux show-option -gv @tokyo-night-tmux_transparent)"

case $SELECTED_THEME in
"storm")
  # ... (Keep Storm as is, or apply similar logic if you use it)
  declare -A THEME=(
    ["background"]="#24283b"
    ["foreground"]="#c0caf5" # Brighter foreground
    ["black"]="#414868"
    ["blue"]="#7aa2f7"
    ["cyan"]="#7dcfff"
    ["green"]="#9ece6a"      # More vibrant green
    ["magenta"]="#bb9af7"
    ["red"]="#f7768e"
    ["white"]="#a9b1d6"
    ["yellow"]="#e0af68"

    ["bblack"]="#414868"
    ["bblue"]="#7aa2f7"
    ["bcyan"]="#7dcfff"
    ["bgreen"]="#41a6b5"
    ["bmagenta"]="#bb9af7"
    ["bred"]="#f7768e"
    ["bwhite"]="#787c99"
    ["byellow"]="#e0af68"
  )
  ;;

"day")
  # ... (Keep Day as is)
  declare -A THEME=(
    ["background"]="#d5d6db"
    ["foreground"]="#343b58"
    ["black"]="#0f0f14"
    ["blue"]="#34548a"
    ["cyan"]="#0f4b6e"
    ["green"]="#33635c"
    ["magenta"]="#5a4a78"
    ["red"]="#8c4351"
    ["white"]="#343b58"
    ["yellow"]="#8f5e15"

    ["bblack"]="#9699a3"
    ["bblue"]="#34548a"
    ["bcyan"]="#0f4b6e"
    ["bgreen"]="#33635c"
    ["bmagenta"]="#5a4a78"
    ["bred"]="#8c4351"
    ["bwhite"]="#343b58"
    ["byellow"]="#8f5815"
  )
  ;;

*)
  # === HIGH CONTRAST NIGHT THEME ===
  declare -A THEME=(
    # 1. Background: Darker (#16161e) instead of (#1a1b26) for deeper contrast
    ["background"]="#16161e"

    # 2. Foreground: Brighter (#c0caf5) instead of (#a9b1d6)
    ["foreground"]="#c0caf5"

    # 3. "Black" (Used for bubbles/inactive): Slightly lighter (#2f334d) to stand out against the new dark bg
    ["black"]="#2f334d"

    # 4. Accents: Pushed slightly towards neon for readability
    ["blue"]="#7aa2f7"
    ["cyan"]="#7dcfff"
    ["green"]="#9ece6a"  # Brighter Green (was #73daca)
    ["magenta"]="#bb9af7"
    ["red"]="#f7768e"
    ["white"]="#c0caf5"
    ["yellow"]="#e0af68"

    # 5. Bold Colors (Used in active bubbles)
    ["bblack"]="#15161e" # The darkest dark (matches bg)
    ["bblue"]="#7aa2f7"
    ["bcyan"]="#7dcfff"
    ["bgreen"]="#9ece6a"
    ["bmagenta"]="#bb9af7"
    ["bred"]="#db4b4b"   # Deep Red for errors
    ["bwhite"]="#ffffff" # Pure White
    ["byellow"]="#e0af68"
  )
  ;;
esac

# Override background with "default" if transparent theme is enabled
if [ "${TRANSPARENT_THEME}" == 1 ]; then
  THEME["background"]="default"
fi

THEME['ghgreen']="#3fb950"
THEME['ghmagenta']="#A371F7"
THEME['ghred']="#d73a4a"
THEME['ghyellow']="#d29922"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
