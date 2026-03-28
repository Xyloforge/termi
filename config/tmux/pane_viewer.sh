#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Pane Viewer — View pane content in a searchable popup      ║
# ║                                                             ║
# ║  Usage: pane_viewer.sh                                      ║
# ║                                                             ║
# ║  If multiple panes: fzf picker to choose which pane         ║
# ║  Then opens full scrollback in less (vim-style navigation)  ║
# ║                                                             ║
# ║  Controls (in less):                                        ║
# ║    /pattern  → search forward (like Cmd+F)                  ║
# ║    ?pattern  → search backward                              ║
# ║    n / N     → next / previous match                        ║
# ║    g / G     → top / bottom                                 ║
# ║    j / k     → scroll down / up                             ║
# ║    Ctrl-F/B  → page down / up                               ║
# ║    q         → close                                        ║
# ╚══════════════════════════════════════════════════════════════╝

# -u: error on unbound vars, but no -e/-pipefail so capture-pane
# failures don't silently kill the popup before less opens
set -u

# ── Get pane list ──
CURRENT_SESSION=${1:-$(tmux display-message -p '#{session_name}')}
CURRENT_WINDOW=${2:-$(tmux display-message -p '#{window_index}')}

# List all panes using pane_id (%N) — globally unique, works as capture-pane target directly
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
    # fzf picker with preview of pane content
    # {1} is the pane_id (%N) — used directly as capture-pane target
    SELECTED=$(echo "$PANE_LIST" | \
        awk -F'|' '{printf "%-6s  %-16s  %-40s  %s\n", $1, $2, $3, $4}' | \
        fzf \
            --prompt='  Pane: ' \
            --header='Select a pane to view  │  Enter=view  Esc=cancel' \
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

# ── Capture full scrollback and display in less ──
TMPFILE=$(mktemp /tmp/pane_viewer.XXXXXX)
trap "rm -f '$TMPFILE'" EXIT

# Use pane_id directly as target — more reliable than session:window.index
tmux capture-pane -t "$TARGET_PANE" -p -J -S - -E - 2>/dev/null > "$TMPFILE" || true

if [[ ! -s "$TMPFILE" ]]; then
    echo ""
    echo "  (no scrollback captured for pane $TARGET_PANE)"
    echo ""
    echo "  Press any key to close..."
    read -r -s -n1 </dev/tty 2>/dev/null || read -r -s -n1
    exit 0
fi

# Open in less with vim-like keybindings and search
# -R: raw control chars (colors)  -i: case-insensitive search
# -S: no line wrap (horizontal scroll)  +G: start at bottom (latest output)
less -RiS +G "$TMPFILE"
