#!/bin/bash
# Installs extensions + copies settings & keybindings for VS Code, Cursor, and Antigravity
# Works on macOS, Linux, and Windows (Git Bash / WSL)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Detect OS and set config paths ────────────────────────────────
detect_paths() {
    case "$(uname -s)" in
        Darwin)
            VSCODE_DIR="$HOME/Library/Application Support/Code/User"
            CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
            ANTIGRAVITY_DIR="$HOME/Library/Application Support/Antigravity/User"
            ;;
        Linux)
            VSCODE_DIR="$HOME/.config/Code/User"
            CURSOR_DIR="$HOME/.config/Cursor/User"
            ANTIGRAVITY_DIR="$HOME/.config/Antigravity/User"
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            VSCODE_DIR="$APPDATA/Code/User"
            CURSOR_DIR="$APPDATA/Cursor/User"
            ANTIGRAVITY_DIR="$APPDATA/Antigravity/User"
            ;;
        *)
            echo "Unknown OS: $(uname -s)"
            exit 1
            ;;
    esac
}

# ── Install extensions for a given editor CLI ─────────────────────
install_extensions() {
    local cmd="$1"
    local name="$2"

    if ! command -v "$cmd" &> /dev/null; then
        echo "  Skipping $name extensions ('$cmd' not found)"
        return
    fi

    echo "  Installing $name extensions..."
    "$cmd" --install-extension Catppuccin.catppuccin-vsc
    "$cmd" --install-extension PKief.material-icon-theme
    "$cmd" --install-extension vscodevim.vim
}

# ── Copy settings & keybindings for one editor ────────────────────
copy_config() {
    local editor_name="$1"
    local config_dir="$2"
    local source_dir="$3"

    if [ ! -d "$config_dir" ]; then
        echo "  Skipping $editor_name config (dir not found: $config_dir)"
        return
    fi

    # Settings — use editor-specific if exists, otherwise fall back to vscode shared
    if [ -f "$source_dir/settings.json" ]; then
        cp "$source_dir/settings.json" "$config_dir/settings.json"
        echo "  Copied $editor_name settings.json"
    elif [ -f "$REPO_ROOT/config/vscode/settings.json" ]; then
        cp "$REPO_ROOT/config/vscode/settings.json" "$config_dir/settings.json"
        echo "  Copied $editor_name settings.json (shared from vscode)"
    fi

    # Keybindings
    if [ -f "$source_dir/keybindings.json" ]; then
        cp "$source_dir/keybindings.json" "$config_dir/keybindings.json"
        echo "  Copied $editor_name keybindings.json"
    fi
}

# ── Main ──────────────────────────────────────────────────────────
detect_paths

echo "=== Extensions ==="
install_extensions "code"         "VS Code"
install_extensions "cursor"       "Cursor"
install_extensions "antigravity"  "Antigravity"

echo ""
echo "=== Settings & Keybindings ==="
copy_config "VS Code"      "$VSCODE_DIR"      "$REPO_ROOT/config/vscode"
copy_config "Cursor"        "$CURSOR_DIR"      "$REPO_ROOT/config/cursor"
copy_config "Antigravity"   "$ANTIGRAVITY_DIR" "$REPO_ROOT/config/antigravity"

echo ""
echo "Done. Restart your editors to apply changes."
