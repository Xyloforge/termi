#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Window Finder — fuzzy switch across all sessions/windows   ║
# ║                                                             ║
# ║  Bound to Prefix+f. Also reachable from the command palette.║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

CHOICE=$(tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name} #{pane_current_path}' \
    | fzf --prompt='  ' \
          --header='Switch Window · Tab / Shift+Tab to navigate · Enter to switch · Esc to cancel' \
          --layout=reverse \
          --border=none \
          --with-nth=1,2,3 \
          --delimiter=' ' \
          --bind='tab:down,btab:up' \
          --color='bg+:#313244,fg+:#CDD6F4,hl:#F38BA8,hl+:#F38BA8,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70' \
    | awk '{print $1}')

[ -z "$CHOICE" ] && exit 0

tmux switch-client -t "$CHOICE"
