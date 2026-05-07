#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Yank Preview — popup body                                  ║
# ║                                                             ║
# ║  Renders the preview file passed in $1 inside a tmux popup. ║
# ║  Waits for: q = close, e = open in editor.                  ║
# ║                                                             ║
# ║  Lives in its own file so it always runs under bash         ║
# ║  (the shebang) — not the user's default-shell, which may be ║
# ║  zsh and parses `read -rsn1` differently.                   ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

PREVIEW_FILE="${1:?preview file required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat "$PREVIEW_FILE"
echo ''

while true; do
    if [[ -r /dev/tty ]]; then
        read -rsn1 key </dev/tty
    else
        read -rsn1 key
    fi
    case "$key" in
        q|Q) break ;;
        e|E)
            cat "$PREVIEW_FILE" \
                | sed '1,/─────/d' \
                | sed '/─────/,$d' \
                | sed '/^$/d' \
                | "$SCRIPT_DIR/open_in_editor.sh"
            break
            ;;
    esac
done

rm -f "$PREVIEW_FILE"
