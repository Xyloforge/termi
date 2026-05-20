#!/usr/bin/env bash
# Cross-session last-window swap (CS-style Q)
# Called with current session and window so tmux formats are pre-substituted.
# Usage: swap_last_window.sh <current_session> <current_window_index>

CUR_SESSION="$1"
CUR_WINDOW="$2"

PREV_SESSION=$(tmux show-option -gv @prev_swap_session 2>/dev/null)
PREV_WINDOW=$(tmux show-option -gv @prev_swap_window 2>/dev/null)

# Save current position as the new "previous" before jumping
tmux set-option -g @prev_swap_session "$CUR_SESSION"
tmux set-option -g @prev_swap_window "$CUR_WINDOW"

if [ -n "$PREV_SESSION" ] && [ -n "$PREV_WINDOW" ]; then
    tmux switch-client -t "$PREV_SESSION" 2>/dev/null && \
    tmux select-window -t "$PREV_SESSION:$PREV_WINDOW" 2>/dev/null
fi
