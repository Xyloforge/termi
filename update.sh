#!/bin/bash

# Termi Update Script
# Propagates changes from this repo to your active configuration
# and reloads running applications (Alacritty, Tmux).

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "🔄 Updating Termi configuration..."

# 1. Update Symlinks
# This ensures any new config files added to the repo are linked.
# 'ln -sf' is safe: it overwrites links but not the target files (since target is in repo)
echo "🔗 Refreshing symlinks..."
mkdir -p "$CONFIG_DIR/alacritty" "$CONFIG_DIR/tmux"

ln -sf "$REPO_DIR/config/alacritty/alacritty.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"
ln -sf "$REPO_DIR/config/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"

# 2. Add Auto-Tmux to Zsh (if missing)
# This handles the case where you update Zsh logic in the repo
ZSHRC="$HOME/.zshrc"
SNIPPET="$REPO_DIR/zsh/auto-tmux.zsh"
if ! grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
    echo "🐚 Adding missing auto-tmux logic to $ZSHRC..."
    echo "" >> "$ZSHRC"
    cat "$SNIPPET" >> "$ZSHRC"
fi

# 3. Touch Alacritty config to force reload (in case it didn't pick up)
if [ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]; then
    touch "$CONFIG_DIR/alacritty/alacritty.toml"
    echo "✅ Alacritty config refreshed (touched)."
fi

# 4. Reload Tmux
if command -v tmux &> /dev/null && pgrep tmux > /dev/null; then
    echo "🔄 Reloading active Tmux session..."
    tmux source-file "$CONFIG_DIR/tmux/tmux.conf" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Tmux reloaded."
    else
        echo "⚠️  Tmux reload check failed. Check syntax or logs."
    fi
    
    # 5. Update Plugins (Optional, but good for 'update')
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
         echo "🔌 Note: To update Tmux plugins, press Prefix + U inside Tmux."
         # We could run: "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
         # But it's often interactive.
    fi
else
    echo "ℹ️  Tmux not running; changes will apply on next start."
fi

echo "✨ Update complete."
