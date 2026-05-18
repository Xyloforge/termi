#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Command Palette — Raycast / Cmd+P style fuzzy launcher     ║
# ║                                                             ║
# ║  Usage:                                                     ║
# ║    Prefix + /        → open palette                         ║
# ║    Cmd + /  (macOS)  → open palette (no prefix needed)      ║
# ║    Alt + /  (Linux)  → open palette (no prefix needed)      ║
# ║                                                             ║
# ║  Type to filter · Enter to run · Esc to cancel              ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# Resolve current pane id. The binding tries to pass it as $1, but some tmux
# versions don't expand `#{...}` inside display-popup's shell-command, so $1
# may arrive as the literal string `#{pane_id}` — fall back to display-message.
PANE_ID="${1:-}"
case "$PANE_ID" in
    ''|'#{'*) PANE_ID="$(tmux display-message -p '#{pane_id}')" ;;
esac

# ── Entries: id|label|shortcut ──
# Label is what user sees and searches over. Shortcut is informational.
ENTRIES=$(cat <<'EOF'
split_v|  Split pane right (vertical)|Prefix+d
split_h|  Split pane below (horizontal)|Prefix+D
new_window|  New window|Prefix+y
kill_pane|  Kill current pane|Prefix+w
kill_window|  Kill current window|Prefix+W
zoom|  Zoom toggle current pane|Prefix+z
display_panes|  Show pane numbers|Prefix+o
swap_pane_next|  Swap with next pane|—
swap_pane_prev|  Swap with previous pane|—
swap_pane_drag|  Swap panes by dragging (info)|Option+drag
break_pane|  Break pane into new window|—
choose_window|  Choose window (visual tree)|Prefix+p
choose_session|  Choose session (visual tree)|—
scratch_borrow|  Scratch view: borrow pane from another window|Prefix+b
scratch_return|  Scratch view: return all borrowed panes home|Prefix+B
window_finder|  Find window by name (fzf)|Prefix+f
prev_window|  Previous window|Prefix+N
next_window|  Next window|—
last_window|  Last (most recent) window|—
rename_window|  Rename current window|Prefix+R
new_session|  New session|—
detach|  Detach from session|—
copy_mode|  Enter copy mode (vim selection)|Prefix+v
log_grabber|  Log grabber (search scrollback)|Prefix+g
popup_terminal|  Floating terminal popup|Prefix+P
synchronize_panes|  Toggle sync typing across panes|—
clock_mode|  Show clock|—
google_search|  Google search prompt|Prefix+G
reload_config|  Reload tmux config|Prefix+r
list_keys|  Show all keybindings|Prefix+? (default)
find_process|  Find & kill process (fzf)|Cmd+Shift+F
EOF
)

# ── Run fzf inside the popup ──
SELECTED=$(echo "$ENTRIES" | fzf \
    --prompt='  ' \
    --header='Command Palette · type to search · Tab / Shift+Tab navigate · Enter run · Esc cancel' \
    --layout=reverse \
    --border=none \
    --height=100% \
    --delimiter='|' \
    --with-nth=2,3 \
    --no-info \
    --bind='tab:down,btab:up' \
    --color='bg+:#313244,fg+:#CDD6F4,hl:#89B4FA,hl+:#89B4FA,pointer:#89B4FA,prompt:#89B4FA,header:#585B70,info:#585B70' \
) || exit 0

[ -z "$SELECTED" ] && exit 0

CHOICE=$(echo "$SELECTED" | cut -d'|' -f1)

# ── defer: run a tmux command after this popup closes ──
# Some actions (display-panes, command-prompt, nested popups) behave better
# when fired from outside the current popup. We background a short-sleep + exec.
defer() {
    (sleep 0.15; tmux "$@") >/dev/null 2>&1 &
    disown
}

# Detect platform for Google search opener
if [[ "$(uname)" == "Darwin" ]]; then
    OPENER="open"
else
    OPENER="xdg-open"
fi

case "$CHOICE" in
    split_v)            tmux split-window -h -t "$PANE_ID" -c "#{pane_current_path}" ;;
    split_h)            tmux split-window -v -t "$PANE_ID" -c "#{pane_current_path}" ;;
    new_window)         tmux new-window -c "#{pane_current_path}" ;;
    kill_pane)          tmux kill-pane -t "$PANE_ID" ;;
    kill_window)        tmux kill-window ;;
    zoom)               tmux resize-pane -Z -t "$PANE_ID" ;;
    display_panes)      defer display-panes ;;
    swap_pane_next)     tmux swap-pane -D ;;
    swap_pane_prev)     tmux swap-pane -U ;;
    swap_pane_drag)     tmux display-message "  Hold Option and drag a pane onto another to swap" ;;
    break_pane)         tmux break-pane ;;
    choose_window)      defer choose-tree -Zw ;;
    choose_session)     defer choose-tree -Zs ;;
    scratch_borrow)     defer display-popup -E -w 70% -h 70% "~/.config/tmux/scratch_borrow.sh '$PANE_ID' '$(tmux display-message -p '#{session_name}')' '$(tmux display-message -p '#{window_id}')' '$(tmux display-message -p '#{window_name}')'" ;;
    scratch_return)     tmux run-shell "~/.config/tmux/scratch_return.sh" ;;
    window_finder)      defer display-popup -E -w 60% -h 50% "~/.config/tmux/window_finder.sh" ;;
    prev_window)        tmux previous-window ;;
    next_window)        tmux next-window ;;
    last_window)        tmux last-window ;;
    rename_window)      defer command-prompt -I "#W" "rename-window '%%'" ;;
    new_session)        defer command-prompt -p "new session name:" "new-session -d -s '%%'" ;;
    detach)             tmux detach-client ;;
    copy_mode)          defer copy-mode -t "$PANE_ID" ;;
    log_grabber)        defer display-popup -E -w 80% -h 90% "~/.config/tmux/log_grabber.sh" ;;
    popup_terminal)     defer display-popup -E -w 80% -h 80% -d "#{pane_current_path}" "zsh" ;;
    synchronize_panes)  tmux setw synchronize-panes ;;
    clock_mode)         defer clock-mode -t "$PANE_ID" ;;
    google_search)      defer command-prompt -p "🔍 Google:" "run-shell '$OPENER \"https://www.google.com/search?q=%1\"'" ;;
    reload_config)      tmux source-file ~/.config/tmux/tmux.conf \; display-message "  Config Reloaded" ;;
    list_keys)          defer list-keys ;;
    find_process)       defer display-popup -E -w 90% -h 90% "bash ~/.config/tmux/find_process_fzf.sh" ;;
esac
