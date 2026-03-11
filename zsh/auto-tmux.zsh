# -----------------------------------------------------------------------------
# Auto-Tmux Configuration (Added by Install Script)
# -----------------------------------------------------------------------------

# Ensure Homebrew bin is in path (common issue on M1/M2/M3 Macs, and Linuxbrew)
export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:$PATH"

# Only run if:
# 1. Not already in Tmux
# 2. Interactive shell
# 3. We are in Alacritty (prevents it opening in VSCode/IntelliJ terminals)
if [[ -z "$TMUX" ]] && [[ -t 0 ]] && [[ "$TERM" == "alacritty" || "$TERM" == "xterm-256color" ]]; then
    # We check if 'tmux' command exists
    if command -v tmux &> /dev/null; then
        # 'exec' replaces the current shell with tmux, so exiting tmux closes the window.
        # -u forces UTF-8 (important for icons)
        exec tmux -u new-session -A -s main
    fi
fi
