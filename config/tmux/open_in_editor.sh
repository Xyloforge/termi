#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Editor Opener — Open text in preferred editor              ║
# ║                                                             ║
# ║  Usage:                                                     ║
# ║    echo "text" | open_in_editor.sh                          ║
# ║    open_in_editor.sh < file.txt                             ║
# ║                                                             ║
# ║  First run: picks from available editors, saves preference  ║
# ║  Subsequent: opens instantly with saved editor              ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

PREFS_DIR="$HOME/.config/termi"
PREFS_FILE="$PREFS_DIR/preferences"

# ── Get saved editor preference ──
get_preferred_editor() {
    if [[ -f "$PREFS_FILE" ]]; then
        grep '^editor=' "$PREFS_FILE" 2>/dev/null | cut -d'=' -f2
    fi
}

# ── Save editor preference ──
save_preferred_editor() {
    mkdir -p "$PREFS_DIR"
    if [[ -f "$PREFS_FILE" ]]; then
        # Update existing preference
        if grep -q '^editor=' "$PREFS_FILE" 2>/dev/null; then
            sed -i.bak "s/^editor=.*/editor=$1/" "$PREFS_FILE" && rm -f "${PREFS_FILE}.bak"
        else
            echo "editor=$1" >> "$PREFS_FILE"
        fi
    else
        echo "editor=$1" > "$PREFS_FILE"
    fi
}

# ── Detect available editors ──
detect_editors() {
    local editors=()
    command -v cursor &>/dev/null && editors+=("cursor")
    command -v antigravity &>/dev/null && editors+=("antigravity")
    command -v code &>/dev/null   && editors+=("code")
    command -v nvim &>/dev/null   && editors+=("nvim")
    command -v vim &>/dev/null    && editors+=("vim")
    command -v nano &>/dev/null   && editors+=("nano")
    echo "${editors[@]}"
}

# ── Pick editor (first-time setup) ──
pick_editor() {
    local editors
    editors=($(detect_editors))

    if [[ ${#editors[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    if [[ ${#editors[@]} -eq 1 ]]; then
        echo "${editors[0]}"
        return
    fi

    # Show picker
    local chosen
    chosen=$(printf '%s\n' "${editors[@]}" | fzf \
        --prompt="  Pick your editor: " \
        --header="This choice will be remembered" \
        --layout=reverse \
        --height=40% \
        --color='bg+:#313244,fg+:#CDD6F4,hl:#F38BA8,hl+:#F38BA8,pointer:#CBA6F7,prompt:#CBA6F7,header:#585B70' \
    ) || echo ""

    echo "$chosen"
}

# ── Resolve which editor to use ──
resolve_editor() {
    # 1. Check saved preference
    local saved
    saved=$(get_preferred_editor)
    if [[ -n "$saved" ]] && command -v "$saved" &>/dev/null; then
        echo "$saved"
        return
    fi

    # 2. First-time: pick and save
    local chosen
    chosen=$(pick_editor)
    if [[ -n "$chosen" ]]; then
        save_preferred_editor "$chosen"
        echo "$chosen"
    fi
}

# ── Main: read stdin, write to temp file, open in editor ──
CONTENT=$(cat)

if [[ -z "$CONTENT" ]]; then
    echo "Nothing to open."
    exit 0
fi

EDITOR_CMD=$(resolve_editor)

if [[ -z "$EDITOR_CMD" ]]; then
    echo "❌ No editor found."
    exit 1
fi

# Write to a temp .log file so editors give it syntax highlighting
TMPFILE=$(mktemp /tmp/grabbed_XXXXXX.log)
echo "$CONTENT" > "$TMPFILE"

# Open in editor (detached so the popup can close)
nohup "$EDITOR_CMD" "$TMPFILE" &>/dev/null &
