#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Pane Drag-Swap — rearrange panes by mouse drag             ║
# ║                                                             ║
# ║  Hold Option (Alt) and drag from one pane to another to     ║
# ║  swap their positions. Plain drag still selects text.       ║
# ║                                                             ║
# ║  Called from tmux:                                          ║
# ║    bind -n M-MouseDragEnd1Pane run-shell -b "... '#{pane_id}'"
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

SRC_ID="${1:-}"
[ -z "$SRC_ID" ] && exit 0

# Resolve the pane currently under the mouse cursor (drag end position).
DST_ID="$(tmux display-message -p -t '{mouse}' '#{pane_id}' 2>/dev/null || true)"
[ -z "$DST_ID" ] && exit 0

# No-op if user released over the same pane (just a tap with Alt held).
[ "$SRC_ID" = "$DST_ID" ] && exit 0

# Swap pane contents and follow the dragged pane to its new location.
if tmux swap-pane -s "$SRC_ID" -t "$DST_ID" 2>/dev/null; then
    tmux select-pane -t "$DST_ID"
    tmux display-message "  Swapped panes"
fi
