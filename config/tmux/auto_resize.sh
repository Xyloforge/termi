#!/usr/bin/env bash
# The focus hook supplies its pane. Never guess a client in a multi-client server.
set -eu
pane=${2:?pane id required}
IFS='|' read -r window width height zoomed < <(
    tmux display-message -p -t "$pane" '#{window_id}|#{pane_width}|#{pane_height}|#{window_zoomed_flag}'
)
[ -n "$window" ] || exit 0
# Manual zoom takes precedence over automatic layout changes.
[ "$zoomed" = 0 ] || exit 0

case "${1:-}" in
    in)
        if [ "$width" -lt 25 ] || [ "$height" -lt 25 ]; then
            saved=$(tmux show-option -wqv -t "$window" @saved_layout)
            if [ -z "$saved" ]; then
                layout=$(tmux display-message -p -t "$pane" '#{window_layout}')
                tmux set-option -wq -t "$window" @saved_layout "$layout"
            fi
            if [ "$width" -lt 25 ]; then tmux resize-pane -t "$pane" -x 25; fi
            if [ "$height" -lt 25 ]; then tmux resize-pane -t "$pane" -y 25; fi
        fi
        ;;
    out)
        saved=$(tmux show-option -wqv -t "$window" @saved_layout)
        if [ -n "$saved" ]; then
            tmux select-layout -t "$window" "$saved" >/dev/null 2>&1 || true
            tmux set-option -wu -t "$window" @saved_layout
        fi
        ;;
esac
