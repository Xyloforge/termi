#!/bin/bash

# Termi Uninstall Script
# Reverts changes made by install.sh

set -e

CONFIG_DIR="$HOME/.config"
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins/tpm"
ZSHRC="$HOME/.zshrc"

echo "🗑️  Starting uninstallation..."

# 1. Remove Configuration Links
echo "🔌 Removing configurations..."
rm -f "$CONFIG_DIR/alacritty/alacritty.toml"
rm -f "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"
rm -f "$CONFIG_DIR/tmux/tmux.conf"

# Remove directories if they are empty
rmdir "$CONFIG_DIR/alacritty" 2>/dev/null || true
rmdir "$CONFIG_DIR/tmux" 2>/dev/null || true

# 2. Remove Tmux Plugin Manager
if [ -d "$TMUX_PLUGIN_DIR" ]; then
    echo "🔌 Removing Tmux Plugin Manager..."
    rm -rf "$TMUX_PLUGIN_DIR"
fi

# 3. Clean .zshrc
if grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
    echo "🐚 Removing Auto-Tmux snippet from $ZSHRC..."
    # Create backup
    cp "$ZSHRC" "${ZSHRC}.bak"
    echo "   (Backup saved to ${ZSHRC}.bak)"
    
    # Remove the block. 
    # Matches from the header line to the 'fi' closing the block.
    # Note: This pattern assumes the specific structure from auto-tmux.zsh
    # We use a loop in sed to delete the range.
    
    # Platform specific sed
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '/# Auto-Tmux Configuration (Added by Install Script)/,+8d' "$ZSHRC"
        # Also remove the separator line above if present (it was 3 lines of comments, then code)
        # The install script appends 3 header lines + 6 code lines = ~9 lines.
        # Let's use a more robust range deletion if possible, or just exact match.
        # Simpler: Read the file, exclude the lines.
    else
        sed -i '/# Auto-Tmux Configuration (Added by Install Script)/,+8d' "$ZSHRC"
    fi
    
    # Clean up empty lines at the end if we left any (optional)
fi

echo "✅ Configurations removed."

# 4. Uninstall Packages (Optional)
read -p "❓ Do you want to uninstall Alacritty, Tmux, and the Nerd Font? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        echo "📦 Uninstalling packages via Homebrew..."
        brew uninstall --cask alacritty font-jetbrains-mono-nerd-font
        brew uninstall tmux
    elif [ "$OS" = "Linux" ]; then
        echo "🐧 Uninstalling packages..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get remove -y alacritty tmux
        fi
    fi
    echo "✅ Packages uninstalled."
else
    echo "create-react-app kept installed."
fi

echo "✨ Uninstallation complete."
