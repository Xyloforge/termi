#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Scratch View — External-destroy safety net                 ║
# ║                                                             ║
# ║  Fired by the `window-unlinked` hook. Runs on EVERY window  ║
# ║  close, but only does work when:                            ║
# ║    1. There's a state file with borrowed panes recorded,    ║
# ║    2. The __scratch__ window no longer exists.              ║
# ║                                                             ║
# ║  In that case scratch was destroyed by something other than ║
# ║  Prefix+B (e.g. choose-tree's `x`, :kill-window, last pane  ║
# ║  killed, server restart). The borrowed panes are gone, but  ║
# ║  we still kill the placeholder panes left in their origin   ║
# ║  windows and clear the state file, so the next session is   ║
# ║  clean.                                                     ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

STATE_FILE="/tmp/tmux_scratch_state.${USER}"
SCRATCH_NAME="__scratch__"

# Nothing to clean up
[ -f "$STATE_FILE" ] || exit 0

# If scratch is still around, this hook fired for some OTHER window — bail
scratch_alive=$(tmux list-windows -a -F '#{window_name}' 2>/dev/null \
                | grep -cx "$SCRATCH_NAME" || true)
[ "${scratch_alive:-0}" -gt 0 ] && exit 0

# Scratch is gone but state remains → we have orphans to clean up
total=0
placeholders_killed=0
while IFS='|' read -r pane_id _ _ _ placeholder; do
    [ -z "$pane_id" ] && continue
    total=$((total + 1))
    if [ -n "$placeholder" ] && tmux kill-pane -t "$placeholder" 2>/dev/null; then
        placeholders_killed=$((placeholders_killed + 1))
    fi
done < "$STATE_FILE"

rm -f "$STATE_FILE"

if [ "$total" -gt 0 ]; then
    tmux display-message \
        "  Scratch destroyed externally · ${total} borrowed pane(s) lost · ${placeholders_killed} placeholder(s) cleaned"
fi
