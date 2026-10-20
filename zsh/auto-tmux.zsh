# Termi's managed startup is sourced, so updates replace behavior immediately.
export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:$PATH"

if [[ -o interactive && -z "$TMUX" && -t 0 ]] &&
   [[ "$TERM" == alacritty || "$TERM" == xterm-256color ]] &&
   command -v tmux >/dev/null 2>&1; then
    # Reopening a terminal attaches to recent live work, independent of cwd.
    if tmux has-session 2>/dev/null; then
        exec tmux -u attach-session
    else
        # Session 0 is resurrect's disposable bootstrap session. Concurrent
        # terminal launches join it rather than creating competing workspaces.
        exec env TERMI_BOOTSTRAP=1 tmux -u new-session -A -s 0
    fi
fi
