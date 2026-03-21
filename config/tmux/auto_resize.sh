#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Configuration: Define your "Comfort Zone"
TARGET_W=25
TARGET_H=25

if [ "$1" = "in" ]; then
    # 1. Get current dimensions
    W=$(tmux display-message -p '#{pane_width}')
    H=$(tmux display-message -p '#{pane_height}')
    
    # 2. Save layout ONLY if we are about to change something
    if [ "$W" -lt "$TARGET_W" ] || [ "$H" -lt "$TARGET_H" ]; then
        LAYOUT=$(tmux display-message -p '#{window_layout}')
        tmux set-window-option -pq @saved_layout "$LAYOUT"

        # 3. Smart Resize Logic
        # If width is small, expand width. If height is small, expand height.
        # This allows tmux to keep your other splits alive.
        if [ "$W" -lt "$TARGET_W" ] && [ "$H" -lt "$TARGET_H" ]; then
            # Both small? Resize both.
            tmux resize-pane -x "$TARGET_W" -y "$TARGET_H"
        elif [ "$W" -lt "$TARGET_W" ]; then
            # Just narrow? Only touch width.
            tmux resize-pane -x "$TARGET_W"
        elif [ "$H" -lt "$TARGET_H" ]; then
            # Just short? Only touch height.
            tmux resize-pane -y "$TARGET_H"
        fi
    fi

elif [ "$1" = "out" ]; then
    SAVED=$(tmux display-message -p '#{@saved_layout}')
    if [ -n "$SAVED" ]; then
        # Use -q to prevent flickering from error messages
        tmux select-layout -q "$SAVED"
        tmux set-window-option -pq -u @saved_layout
    fi
fi