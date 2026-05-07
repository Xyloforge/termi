#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Scratch View — Borrow                                      ║
# ║                                                             ║
# ║  Pulls your current pane + a picked pane from another       ║
# ║  window into a dedicated SCRATCH window so you can see them ║
# ║  side by side. Press again to add more panes. Prefix+B      ║
# ║  returns everything home and tears down the scratch.        ║
# ║                                                             ║
# ║  Panes are MOVED, not copied — same processes stay alive.   ║
# ║  If borrowing would empty an origin window, a placeholder   ║
# ║  pane is left behind so the window survives.                ║
# ║                                                             ║
# ║  Debug:  cat /tmp/tmux_scratch_debug.log                    ║
# ╚══════════════════════════════════════════════════════════════╝

# Always log stderr + xtrace to a fresh file so we can see what failed
DEBUG_LOG="/tmp/tmux_scratch_debug.log"
exec 2>"$DEBUG_LOG"
echo "=== $(date) scratch_borrow.sh invoked  args=[$*]" >&2
set -x

set -euo pipefail
trap 'echo "ERR at line $LINENO (exit=$?)" >&2' ERR

STATE_FILE="/tmp/tmux_scratch_state.${USER}"
SCRATCH_NAME="__scratch__"

# Always fetch current pane info via display-message. Some tmux versions
# don't expand `#{...}` formats inside display-popup's shell-command
# argument, so we can't rely on the binding to substitute them for us.
# display-message -p ALWAYS evaluates formats, regardless of tmux version.
# Use | as a separator since session/window names can contain spaces.
IFS='|' read -r CUR_PANE CUR_SESSION CUR_WINDOW_ID CUR_WINDOW_NAME \
    < <(tmux display-message -p '#{pane_id}|#{session_name}|#{window_id}|#{window_name}')
echo "resolved: pane=$CUR_PANE session=$CUR_SESSION window=$CUR_WINDOW_ID name=$CUR_WINDOW_NAME" >&2

# ── Locate existing scratch window (if any) ──
scratch_id=$(tmux list-windows -a -F '#{window_id}|#{window_name}' \
            | awk -F'|' -v n="$SCRATCH_NAME" '$2==n {print $1; exit}' || true)

# Sanity-check stale state from prior crash
if [ -f "$STATE_FILE" ] && [ -z "$scratch_id" ]; then
    rm -f "$STATE_FILE"
fi

# Helper: leave a placeholder pane if `target_window` would otherwise become empty.
# Returns the placeholder pane id on stdout, or empty string.
leave_placeholder() {
    local target_window="$1"
    local panes
    panes=$(tmux list-panes -t "$target_window" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$panes" = "1" ]; then
        tmux split-window -d -t "$target_window" -P -F '#{pane_id}' \
            "printf '\\033[2J\\033[H  ⏳ Pane borrowed by SCRATCH VIEW\n  Press Prefix+B (in the __scratch__ window) to return it here.\n'; while true; do sleep 3600; done"
    else
        echo ""
    fi
}

# ── Build picker data: every pane EXCEPT scratch's own and the current one ──
PICKER_DATA=$(tmux list-panes -a -F '#{pane_id}|  #{session_name}:#{window_index}.#{pane_index}  #{window_name}  ▸  #{pane_current_command}  ·  #{pane_current_path}|#{window_id}|#{session_name}|#{window_name}' \
              | awk -F'|' -v skip="${scratch_id:-NONE}" -v cur="$CUR_PANE" '$3 != skip && $1 != cur')

if [ -z "$PICKER_DATA" ]; then
    tmux display-message "  No other panes available to borrow"
    exit 0
fi

# Mark already-borrowed panes so user can see what's already in scratch
if [ -f "$STATE_FILE" ]; then
    while IFS='|' read -r b_pane _ _ _ _; do
        [ -z "$b_pane" ] && continue
        PICKER_DATA=$(echo "$PICKER_DATA" | sed "s|^${b_pane}|.*|& [in scratch]|")
    done < "$STATE_FILE"
fi

CHOICE=$(echo "$PICKER_DATA" | fzf \
    --prompt='  borrow ' \
    --header='Pick a pane · Tab / Shift+Tab navigate · Ctrl+/ resize preview · Esc cancel' \
    --layout=reverse --border=none --height=100% \
    --delimiter='|' --with-nth=2 --no-info --ansi \
    --preview='~/.config/tmux/preview_target.sh {1}' \
    --preview-window='bottom,60%,border-top,wrap' \
    --bind='tab:down,btab:up' \
    --bind='ctrl-/:change-preview-window(right,55%,border-left|hidden|bottom,60%,border-top)' \
    --color='bg+:#313244,fg+:#CDD6F4,hl:#89B4FA,hl+:#89B4FA,pointer:#89B4FA,prompt:#89B4FA,header:#585B70,preview-bg:#1E1E2E,preview-fg:#CDD6F4,preview-border:#313244')

[ -z "$CHOICE" ] && exit 0

borrowed_pane=$(echo "$CHOICE" | cut -d'|' -f1)
origin_window_id=$(echo "$CHOICE" | cut -d'|' -f3)
origin_session=$(echo "$CHOICE" | cut -d'|' -f4)
origin_window_name=$(echo "$CHOICE" | cut -d'|' -f5)

# Already borrowed?
if [ -f "$STATE_FILE" ] && grep -q "^${borrowed_pane}|" "$STATE_FILE"; then
    tmux display-message "  That pane is already in scratch"
    exit 0
fi

# ── Create scratch window if needed (with throwaway seed pane) ──
seed_pane=""
if [ -z "$scratch_id" ]; then
    # NOTE: must use `while true; do sleep 3600; done` not `sleep infinity` —
    # macOS BSD sleep rejects non-numeric arguments and the seed pane would
    # die instantly, taking the scratch window with it.
    scratch_id=$(tmux new-window -d -P -F '#{window_id}' -n "$SCRATCH_NAME" \
        "printf '  📌 SCRATCH VIEW — initialising...\n'; while true; do sleep 3600; done")
    seed_pane=$(tmux list-panes -t "$scratch_id" -F '#{pane_id}' | head -1)
fi

# Helper: move a pane into scratch and record state
add_to_scratch() {
    local pane="$1" sess="$2" win_id="$3" win_name="$4"
    if [ -f "$STATE_FILE" ] && grep -q "^${pane}|" "$STATE_FILE"; then
        return 0
    fi
    local placeholder
    placeholder=$(leave_placeholder "$win_id")
    # Use the FIRST pane currently in scratch as the join target — more reliable
    # than passing a window id (some tmux versions are picky).
    local target_pane
    target_pane=$(tmux list-panes -t "$scratch_id" -F '#{pane_id}' 2>/dev/null | head -1)
    if [ -z "$target_pane" ]; then
        echo "  scratch window has no panes to target!" >&2
        return 1
    fi
    tmux join-pane -s "$pane" -t "$target_pane"
    echo "${pane}|${sess}|${win_id}|${win_name}|${placeholder}" >> "$STATE_FILE"
}

# Move current pane in (only on first borrow)
add_to_scratch "$CUR_PANE" "$CUR_SESSION" "$CUR_WINDOW_ID" "$CUR_WINDOW_NAME"

# Move borrowed pane in
add_to_scratch "$borrowed_pane" "$origin_session" "$origin_window_id" "$origin_window_name"

# Now safe to kill the seed pane (only if we just created the scratch)
if [ -n "$seed_pane" ]; then
    tmux kill-pane -t "$seed_pane" 2>/dev/null || true
fi

# Tile the layout for nice side-by-side default
tmux select-layout -t "$scratch_id" tiled 2>/dev/null || true

# Switch the *client* to scratch (more reliable from inside a popup than select-window)
tmux switch-client -t "$scratch_id"
tmux display-message "  Borrowed → SCRATCH (Prefix+B to return all)"
echo "=== success at $(date)" >&2
