#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Session Finder — fuzzy switch across all sessions          ║
# ║                                                             ║
# ║  Replaces tmux's built-in `choose-tree -s` so we get Tab /  ║
# ║  Shift+Tab navigation (and the same look as window_finder). ║
# ║                                                             ║
# ║  Bound to Prefix+s (Cmd+P from Alacritty).                  ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

CHOICE=$(tmux list-sessions -F '#{session_name}|  #{session_name}  ·  #{session_windows} window(s)#{?session_attached, · attached,}' \
    | fzf \
        --prompt='  switch session ' \
        --header='Tab / Shift+Tab to navigate · Enter to switch · Esc to cancel' \
        --layout=reverse \
        --border=none \
        --height=100% \
        --no-info \
        --delimiter='|' \
        --with-nth=2 \
        --bind='tab:down,btab:up' \
        --color='bg+:#313244,fg+:#CDD6F4,hl:#89B4FA,hl+:#89B4FA,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70' \
    | cut -d'|' -f1)

[ -z "$CHOICE" ] && exit 0

tmux switch-client -t "$CHOICE"
