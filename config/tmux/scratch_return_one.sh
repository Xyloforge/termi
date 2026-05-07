#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Scratch View — Return a single pane                        ║
# ║                                                             ║
# ║  Wired into Prefix+w when the active window is __scratch__. ║
# ║                                                             ║
# ║    • If the focused pane is a borrowed one → return home    ║
# ║      and clean up its placeholder.                          ║
# ║    • If it's a pane you created inside scratch (untracked)  ║
# ║      → just kill it like normal kill-pane would.            ║
# ╚══════════════════════════════════════════════════════════════╝

DEBUG_LOG="/tmp/tmux_scratch_debug.log"
exec 2>>"$DEBUG_LOG"
echo "=== $(date) scratch_return_one.sh args=[$*]" >&2
set -x
set -euo pipefail
trap 'echo "ERR at line $LINENO (exit=$?)" >&2' ERR

STATE_FILE="/tmp/tmux_scratch_state.${USER}"
PANE_ID="${1:-}"

# Defensive: some tmux versions don't expand #{pane_id} in command args
case "$PANE_ID" in
    ''|'#{'*) PANE_ID="$(tmux display-message -p '#{pane_id}')" ;;
esac

# Untracked pane (user-created inside scratch) → kill normally
if [ ! -f "$STATE_FILE" ] || ! grep -q "^${PANE_ID}|" "$STATE_FILE"; then
    tmux kill-pane -t "$PANE_ID"
    exit 0
fi

# Borrowed pane → return home
LINE=$(grep "^${PANE_ID}|" "$STATE_FILE")
IFS='|' read -r _ origin_session origin_window_id origin_window_name placeholder <<< "$LINE"

# Find or recreate origin window
if tmux list-windows -a -F '#{window_id}' | grep -qx "$origin_window_id"; then
    tmux join-pane -s "$PANE_ID" -t "$origin_window_id"
else
    target=$(tmux new-window -d -t "${origin_session}:" -P -F '#{window_id}' \
             -n "$origin_window_name" "exec ${SHELL:-/bin/bash}")
    seed=$(tmux list-panes -t "$target" -F '#{pane_id}' | head -1)
    tmux join-pane -s "$PANE_ID" -t "$target"
    tmux kill-pane -t "$seed" 2>/dev/null || true
fi

# Clean up the placeholder we left in the origin window
if [ -n "$placeholder" ]; then
    tmux kill-pane -t "$placeholder" 2>/dev/null || true
fi

# Remove this pane's line from state file (and remove file if empty)
grep -v "^${PANE_ID}|" "$STATE_FILE" > "${STATE_FILE}.tmp" || true
if [ -s "${STATE_FILE}.tmp" ]; then
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
else
    rm -f "$STATE_FILE" "${STATE_FILE}.tmp"
fi

tmux display-message "  Pane returned → ${origin_session}:${origin_window_name}"
