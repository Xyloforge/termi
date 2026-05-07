#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Scratch View — Return                                      ║
# ║                                                             ║
# ║  Sends every borrowed pane back to its origin window and    ║
# ║  tears down the SCRATCH window. Placeholder panes left      ║
# ║  behind in origin windows are killed off here.              ║
# ║                                                             ║
# ║  If an origin window has been closed in the meantime, it's  ║
# ║  recreated by name in the same session.                     ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

STATE_FILE="/tmp/tmux_scratch_state.${USER}"
SCRATCH_NAME="__scratch__"

if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
    tmux display-message "  No scratch view active"
    # Best-effort: if a scratch window exists with no state, just delete it
    sid=$(tmux list-windows -a -F '#{window_id}|#{window_name}' \
          | awk -F'|' -v n="$SCRATCH_NAME" '$2==n {print $1; exit}' || true)
    [ -n "$sid" ] && tmux kill-window -t "$sid" 2>/dev/null || true
    rm -f "$STATE_FILE"
    exit 0
fi

scratch_id=$(tmux list-windows -a -F '#{window_id}|#{window_name}' \
            | awk -F'|' -v n="$SCRATCH_NAME" '$2==n {print $1; exit}' || true)

returned=0
missing=0

while IFS='|' read -r pane_id origin_session origin_window_id origin_window_name placeholder; do
    [ -z "$pane_id" ] && continue

    # Track whether the borrowed pane is still alive. Even if it's gone, we
    # still want to clean up the placeholder we left in the origin window.
    pane_alive=true
    if ! tmux list-panes -a -F '#{pane_id}' | grep -qx "$pane_id"; then
        pane_alive=false
        missing=$((missing + 1))
    fi

    if [ "$pane_alive" = "true" ]; then
        # Origin window still exists?
        if tmux list-windows -a -F '#{window_id}' | grep -qx "$origin_window_id"; then
            tmux join-pane -s "$pane_id" -t "$origin_window_id"
        else
            # Recreate origin window in its session, same name
            target=$(tmux new-window -d -t "${origin_session}:" -P -F '#{window_id}' \
                     -n "$origin_window_name" "exec ${SHELL:-/bin/bash}" 2>/dev/null || true)
            if [ -n "$target" ]; then
                new_seed=$(tmux list-panes -t "$target" -F '#{pane_id}' | head -1)
                tmux join-pane -s "$pane_id" -t "$target"
                tmux kill-pane -t "$new_seed" 2>/dev/null || true
            fi
        fi
        returned=$((returned + 1))
    fi

    # Always clean up the placeholder, dead pane or not
    if [ -n "$placeholder" ]; then
        tmux kill-pane -t "$placeholder" 2>/dev/null || true
    fi
done < "$STATE_FILE"

# Clear state
rm -f "$STATE_FILE"

# Kill scratch window (if it still exists and is now empty)
if [ -n "${scratch_id:-}" ]; then
    tmux kill-window -t "$scratch_id" 2>/dev/null || true
fi

if [ "$missing" -gt 0 ]; then
    tmux display-message "  Returned $returned pane(s); $missing missing"
else
    tmux display-message "  Returned $returned pane(s) home"
fi
