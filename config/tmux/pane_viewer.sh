#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Pane Focus — Pick a pane and zoom it to full window        ║
# ║                                                             ║
# ║  Usage: pane_viewer.sh [session] [window]                   ║
# ║                                                             ║
# ║  After selecting:                                           ║
# ║    The chosen pane fills the entire window (live)           ║
# ║    Prefix+z      → unzoom back to normal layout             ║
# ║    Prefix+p      → pick a different pane to focus           ║
# ║    Prefix+v      → enter copy-mode for search (/)           ║
# ╚══════════════════════════════════════════════════════════════╝

set -u

CURRENT_SESSION=${1:-$(tmux display-message -p '#{session_name}')}
CURRENT_WINDOW=${2:-$(tmux display-message -p '#{window_index}')}

# ── Get pane list ──
PANE_LIST=$(tmux list-panes -t "${CURRENT_SESSION}:${CURRENT_WINDOW}" \
    -F '#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_width}x#{pane_height}' 2>/dev/null) || true

PANE_COUNT=$(echo "$PANE_LIST" | grep -c '.' 2>/dev/null || echo 0)

if [[ "$PANE_COUNT" -eq 0 ]]; then
    echo "No panes found in ${CURRENT_SESSION}:${CURRENT_WINDOW}"
    read -r -s -n1
    exit 0
fi

# ── Pick pane ──
if [[ "$PANE_COUNT" -eq 1 ]]; then
    TARGET_PANE=$(echo "$PANE_LIST" | head -1 | cut -d'|' -f1)
else
    SELECTED=$(echo "$PANE_LIST" | \
        awk -F'|' '{printf "%-6s  %-16s  %-40s  %s\n", $1, $2, $3, $4}' | \
        fzf \
            --prompt='  Focus: ' \
            --header='Select a pane to zoom  │  Enter=focus  Esc=cancel' \
            --layout=reverse \
            --border=none \
            --height=100% \
            --preview='tmux capture-pane -t {1} -p -J -S -50 -E - 2>/dev/null' \
            --preview-window='right,60%,wrap' \
            --preview-label=' Preview ' \
            --color='bg+:#313244,fg+:#CDD6F4,hl:#F38BA8,hl+:#F38BA8,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70,preview-bg:#1E1E2E,preview-fg:#CDD6F4' \
    ) || exit 0

    TARGET_PANE=$(echo "$SELECTED" | awk '{print $1}')
fi

[[ -z "$TARGET_PANE" ]] && exit 0

# ── Focus: select the pane and zoom it to fill the window ──
# The popup closes when this script exits, revealing the zoomed pane.
tmux select-pane -t "$TARGET_PANE"
tmux resize-pane -Z -t "$TARGET_PANE"
