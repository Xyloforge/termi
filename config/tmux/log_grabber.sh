#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Log Grabber — Select & Copy terminal output with fzf       ║
# ║                                                             ║
# ║  Usage:                                                     ║
# ║    log_grabber.sh            → search tmux scrollback       ║
# ║    log_grabber.sh <file>     → search a log file            ║
# ║                                                             ║
# ║  Controls:                                                  ║
# ║    Tab       → select/deselect line                         ║
# ║    Enter     → copy selected lines to clipboard             ║
# ║    Ctrl-E    → toggle: show only ERROR/WARN/FATAL lines     ║
# ║    Ctrl-D    → toggle: show only debug/log lines            ║
# ║    Ctrl-A    → reset: show all lines                        ║
# ║    Ctrl-C    → cancel                                       ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Source: scrollback (lazy) or file ──
TMPFILE=$(mktemp /tmp/log_grabber.XXXXXX)
TMPFILE_FULL=$(mktemp /tmp/log_grabber_full.XXXXXX)
trap "rm -f '$TMPFILE' '$TMPFILE_FULL'" EXIT

if [[ $# -ge 1 && -f "$1" ]]; then
    SOURCE_LABEL="📄 $1"
    cat "$1" | grep -v '^[[:space:]]*$' > "$TMPFILE"
    # For file mode, full = same as initial
    cp "$TMPFILE" "$TMPFILE_FULL"
else
    SOURCE_LABEL="📜 Scrollback"

    # Fast: capture last 500 lines instantly
    tmux capture-pane -p -S -500 -J 2>/dev/null | grep -v '^[[:space:]]*$' > "$TMPFILE"

    # Background: capture full scrollback while user browses
    (tmux capture-pane -p -S - -J 2>/dev/null | grep -v '^[[:space:]]*$' > "$TMPFILE_FULL") &
    BG_PID=$!
fi

TOTAL_LINES=$(wc -l < "$TMPFILE" | tr -d ' ')

# ── fzf with lazy-load + filter keybinds + bottom preview ──
SELECTED=$(cat "$TMPFILE" | fzf \
    --multi \
    --tac \
    --no-sort \
    --ansi \
    --prompt="  Grab: " \
    --header="$SOURCE_LABEL ($TOTAL_LINES lines)  │  TAB=select  ^E=errors  ^D=debug  ^A=all  ^Y=full history" \
    --layout=reverse \
    --border=none \
    --height=100% \
    --preview='echo {}' \
    --preview-window='bottom,4,wrap' \
    --preview-label=' Full Line ' \
    --bind="ctrl-y:reload(cat '$TMPFILE_FULL')+change-header($SOURCE_LABEL (FULL)  │  TAB=select  ^E=errors  ^D=debug  ^A=all)" \
    --bind="ctrl-e:reload(grep -i -E '(error|err|warn|warning|fatal|panic)' '$TMPFILE_FULL' 2>/dev/null || grep -i -E '(error|err|warn|warning|fatal|panic)' '$TMPFILE' || echo '  No matches')+change-header($SOURCE_LABEL │ 🔴 ERRORS ONLY  │  ^A=reset)" \
    --bind="ctrl-d:reload(grep -i -E '(debug|log|trace|verbose)' '$TMPFILE_FULL' 2>/dev/null || grep -i -E '(debug|log|trace|verbose)' '$TMPFILE' || echo '  No matches')+change-header($SOURCE_LABEL │ 🟡 DEBUG ONLY  │  ^A=reset)" \
    --bind="ctrl-a:reload(cat '$TMPFILE_FULL' 2>/dev/null || cat '$TMPFILE')+change-header($SOURCE_LABEL  │  TAB=select  ^E=errors  ^D=debug  ^A=all  ^Y=full history)" \
    --color='bg+:#313244,fg+:#CDD6F4,hl:#F38BA8,hl+:#F38BA8,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70,preview-bg:#1E1E2E,preview-fg:#CDD6F4' \
) || { wait ${BG_PID:-} 2>/dev/null; exit 0; }

# Clean up background job
wait ${BG_PID:-} 2>/dev/null || true

# ── Copy to clipboard + show preview inline ──
# (Can't use tmux display-popup here — we're already in one)
if [[ -n "$SELECTED" ]]; then
    # Detect clipboard
    if command -v pbcopy &>/dev/null; then
        echo -n "$SELECTED" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$SELECTED" | xclip -selection clipboard
    elif command -v wl-copy &>/dev/null; then
        echo -n "$SELECTED" | wl-copy
    fi

    LINE_COUNT=$(echo "$SELECTED" | wc -l | tr -d ' ')
    CHAR_COUNT=$(echo -n "$SELECTED" | wc -c | tr -d ' ')

    # Show inline preview (interactive: q=close, e=editor)
    clear
    echo ""
    echo "  ✅ Copied ${LINE_COUNT} line(s), ${CHAR_COUNT} chars"
    echo "  ─────────────────────────────────────────"
    echo ""
    if [[ $LINE_COUNT -le 40 ]]; then
        echo "$SELECTED"
    else
        echo "$SELECTED" | head -20
        echo ""
        echo "  ··· $((LINE_COUNT - 40)) more lines ···"
        echo ""
        echo "$SELECTED" | tail -20
    fi
    echo ""
    echo "  ─────────────────────────────────────────"
    echo "  q = close  │  e = open in editor"
    echo ""

    # Wait for keypress
    while true; do
        read -rsn1 key
        case "$key" in
            q|Q) break ;;
            e|E)
                echo "$SELECTED" | "$SCRIPT_DIR/open_in_editor.sh"
                break
                ;;
        esac
    done
fi
