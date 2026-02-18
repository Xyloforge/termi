#!/bin/bash
# Installs Catppuccin theme + Fonts for VS Code

# Check if 'code' command exists
if ! command -v code &> /dev/null; then
    echo "⚠️  VS Code 'code' command not found. Please enable it in VS Code (Cmd+Shift+P -> Shell Command: Install 'code' command in PATH)."
    echo "   Skipping VS Code extensions installation."
    exit 0
fi

echo "📦 Installing VS Code Extensions..."
# Install Catppuccin Theme
code --install-extension Catppuccin.catppuccin-vsc
# Install Vim (Optional but recommended for termi users)
# code --install-extension vscodevim.vim
# Install Icons
code --install-extension PKief.material-icon-theme

echo "✅ VS Code extensions installed."
echo "ℹ️  To apply the settings: Copy contents of config/vscode/settings.json to your user settings (Cmd+Shift+P -> Open User Settings (JSON))."
