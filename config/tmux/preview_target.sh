#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Preview Target — shared fzf preview helper                 ║
# ║                                                             ║
# ║  Renders content based on what kind of target was given:    ║
# ║                                                             ║
# ║    %pane_id       → just that pane                          ║
# ║    session:window → every pane in that window               ║
# ║    session_name   → every window in that session, with      ║
# ║                     every pane in each (full session view)  ║
# ║                                                             ║
# ║  Each pane gets a colored header (idx · cmd · path · size). ║
# ║  Each window (in session view) gets a top-level banner.     ║
# ╚══════════════════════════════════════════════════════════════╝

TARGET="${1:-}"
[ -z "$TARGET" ] && exit 0

# Catppuccin-ish ANSI: #89B4FA blue, #fab387 peach, #585B70 dim
BLUE='\033[38;2;137;180;250;1m'
PEACH='\033[38;2;250;179;135;1m'
DIM='\033[38;2;88;91;112m'
RESET='\033[0m'

render_window() {
    local target="$1"
    local panes
    panes=$(tmux list-panes -t "$target" \
            -F '#{pane_index}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_width}x#{pane_height}|#{?pane_active,active,}' \
            2>/dev/null || true)

    if [ -z "$panes" ]; then
        echo "(no panes)"
        return
    fi

    while IFS='|' read -r idx pid cmd path size active; do
        [ -z "$pid" ] && continue
        if [ -n "$active" ]; then
            printf "${BLUE}─── pane %s · %s · %s · %s · ★ active ───${RESET}\n\n" "$idx" "$cmd" "$path" "$size"
        else
            printf "${DIM}─── pane %s · %s · %s · %s ───${RESET}\n\n" "$idx" "$cmd" "$path" "$size"
        fi
        tmux capture-pane -pe -t "$pid" 2>/dev/null
        echo ""
    done <<< "$panes"
}

# Case 1: single pane target
if [[ "$TARGET" == %* ]]; then
    tmux capture-pane -pe -t "$TARGET" 2>/dev/null
    exit 0
fi

# Case 2: session-only target → render every window in the session
if [[ "$TARGET" != *:* ]]; then
    SESSION="$TARGET"
    WINDOWS=$(tmux list-windows -t "$SESSION" \
              -F '#{window_index}|#{window_name}|#{?window_active,active,}|#{window_panes}' \
              2>/dev/null || true)

    if [ -z "$WINDOWS" ]; then
        echo "(session unavailable)"
        exit 0
    fi

    while IFS='|' read -r w_idx w_name w_active w_panes; do
        [ -z "$w_idx" ] && continue
        if [ -n "$w_active" ]; then
            printf "\n${PEACH}╔══ window %s · %s · %s pane(s) · ★ current ══╗${RESET}\n\n" \
                "$w_idx" "$w_name" "$w_panes"
        else
            printf "\n${DIM}╔══ window %s · %s · %s pane(s) ══╗${RESET}\n\n" \
                "$w_idx" "$w_name" "$w_panes"
        fi
        render_window "${SESSION}:${w_idx}"
    done <<< "$WINDOWS"
    exit 0
fi

# Case 3: session:window target → just that window's panes
render_window "$TARGET"
