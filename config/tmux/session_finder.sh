#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Session Finder — fuzzy switch across all sessions          ║
# ║                                                             ║
# ║  Bound to Prefix+s (Cmd+P from Alacritty).                  ║
# ║                                                             ║
# ║  Keys:                                                      ║
# ║    Tab / Shift+Tab   navigate                               ║
# ║    Alt+1 .. Alt+9    jump to numbered row + pick            ║
# ║    Ctrl+/            cycle preview position                 ║
# ║    Enter             switch · Esc cancel                    ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

DATA=$(tmux list-sessions -F '#{session_name}|#{session_name}  ·  #{session_windows} window(s)#{?session_attached, · attached,}' \
       | awk -F'|' '{printf "%s|[%d] %s\n", $1, NR, $2}')

CHOICE=$(echo "$DATA" | fzf \
    --prompt='  switch session ' \
    --header='Tab/Shift+Tab nav · Alt+1-9 quick pick · Ctrl+/ preview · Enter switch · Esc cancel' \
    --layout=reverse \
    --border=none \
    --height=100% \
    --no-info \
    --ansi \
    --delimiter='|' \
    --with-nth=2 \
    --preview='~/.config/tmux/preview_target.sh {1}' \
    --preview-window='bottom,60%,border-top,wrap' \
    --bind='tab:down,btab:up' \
    --bind='ctrl-/:change-preview-window(right,55%,border-left|hidden|bottom,60%,border-top)' \
    --bind='alt-1:pos(1)+accept,alt-2:pos(2)+accept,alt-3:pos(3)+accept,alt-4:pos(4)+accept,alt-5:pos(5)+accept,alt-6:pos(6)+accept,alt-7:pos(7)+accept,alt-8:pos(8)+accept,alt-9:pos(9)+accept' \
    --color='bg+:#313244,fg+:#CDD6F4,hl:#89B4FA,hl+:#89B4FA,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70,preview-bg:#1E1E2E,preview-fg:#CDD6F4,preview-border:#313244')

[ -z "$CHOICE" ] && exit 0

TARGET=$(echo "$CHOICE" | cut -d'|' -f1)
tmux switch-client -t "$TARGET"
