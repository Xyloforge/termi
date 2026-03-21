#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Yank Preview — Copy stdin to clipboard and show preview    ║
# ║                                                             ║
# ║  Used by:                                                   ║
# ║    - tmux copy-mode (y key)                                 ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect clipboard command ──
if command -v pbcopy &>/dev/null; then
    CLIP="pbcopy"
elif command -v xclip &>/dev/null; then
    CLIP="xclip -selection clipboard"
elif command -v wl-copy &>/dev/null; then
    CLIP="wl-copy"
else
    tmux display-message "❌ No clipboard tool found"
    exit 1
fi

# ── Read stdin ──
CONTENT=$(cat)

if [[ -z "$CONTENT" ]]; then
    tmux display-message "Nothing to copy"
    exit 0
fi

# ── Copy to clipboard ──
echo -n "$CONTENT" | eval "$CLIP"

LINE_COUNT=$(echo "$CONTENT" | wc -l | tr -d ' ')
CHAR_COUNT=$(echo -n "$CONTENT" | wc -c | tr -d ' ')

# ── Build preview file ──
PREVIEW_FILE=$(mktemp /tmp/yank_preview.XXXXXX)

{
    echo ""
    echo "  ✅ Copied ${LINE_COUNT} line(s), ${CHAR_COUNT} chars"
    echo "  ─────────────────────────────────────────"
    echo ""
    if [[ $LINE_COUNT -le 40 ]]; then
        echo "$CONTENT"
    else
        echo "$CONTENT" | head -20
        echo ""
        echo "  ··· $((LINE_COUNT - 40)) more lines ···"
        echo ""
        echo "$CONTENT" | tail -20
    fi
    echo ""
    echo "  ─────────────────────────────────────────"
    echo "  q = close  │  e = open in editor"
} > "$PREVIEW_FILE"

# ── Show in tmux popup (interactive: q=close, e=editor) ──
tmux display-popup -E -w 70% -h 50% "
    cat '$PREVIEW_FILE'
    echo ''
    while true; do
        read -rsn1 key
        case \"\$key\" in
            q|Q) break ;;
            e|E)
                cat '$PREVIEW_FILE' | sed '1,/─────/d' | sed '/─────/,\$d' | sed '/^$/d' | ~/.config/tmux/open_in_editor.sh
                break
                ;;
        esac
    done
    rm -f '$PREVIEW_FILE'
"
