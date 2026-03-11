#!/bin/bash

# Termi-Migration Install Script
# Sets up Alacritty, Tmux, and Zsh for macOS/Linux

set -e

CONFIG_DIR="$HOME/.config"
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins/tpm"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting Termi setup..."

# 1. OS Detection & Dependency Installation
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    echo "🍎 macOS detected."
    # Check if brew exists
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Please install Homebrew first."
        exit 1
    fi
    # Helper function for safe brew install
    brew_install() {
        if ! brew list "$1" &>/dev/null; then
            echo "   - Installing $1..."
            brew install "$1"
        else
            echo "   - $1 is already installed."
        fi
    }
    
    brew_cask_install() {
        if ! brew list --cask "$1" &>/dev/null; then
             echo "   - Installing (cask) $1..."
             brew install --cask "$1" || echo "⚠️  Failed to install $1 (might be already installed manually)"
        else
             echo "   - $1 (cask) is already installed."
        fi
    }

    echo "📦 Installing packages..."
    # Install Alacritty, Fonts, FZF, Bat
    brew_cask_install alacritty
    brew_cask_install font-jetbrains-mono-nerd-font
    
    # Add taps
    brew tap kopecmaciej/vi-mongo
    brew tap honhimW/tap

    # Install Tmux & Tools
    brew_install tmux
    brew_install fzf
    brew_install bat
    brew_install btop
    brew_install zoxide
    brew_install lazysql
    brew_install vi-mongo
    brew_install ratisui
    brew_install oxker

    # Fix "App can't be opened" error for Alacritty (Code Signing / Quarantine)
    if [ -d "/Applications/Alacritty.app" ]; then
        echo "🛡️  Fixing macOS security quarantine for Alacritty..."
        # Remove the quarantine attribute which causes "damaged" or "cannot check" errors
        sudo xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true
        # Ad-hoc sign it to ensure it runs on Apple Silicon if needed
        codesign --force --deep --sign - /Applications/Alacritty.app 2>/dev/null || true
        echo "✅ Alacritty security fix applied."
    fi
elif [ "$OS" = "Linux" ]; then
    echo "🐧 Linux detected."
    # Simple check for apt
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y tmux fzf bat btop zoxide wget unzip fontconfig lsof
        # Alacritty may not be in all apt repos — install if available, skip otherwise
        sudo apt-get install -y alacritty 2>/dev/null || echo "⚠️  Alacritty not found in apt. Install manually or via snap: 'sudo snap install alacritty --classic'"
        
        echo "📦 Handling JetBrainsMono Nerd Font..."
        FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
        if [ ! -d "$FONT_DIR" ]; then
            echo "   - Downloading and extracting JetBrainsMono Nerd Font..."
            mkdir -p "$FONT_DIR"
            TEMP_DIR=$(mktemp -d)
            if wget -qO "$TEMP_DIR/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
                unzip -qo "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"
                fc-cache -fv &> /dev/null
                echo "   ✅ JetBrainsMono Nerd Font installed."
            else
                echo "   ⚠️ Failed to download JetBrainsMono Nerd Font. Please install manually."
            fi
            rm -rf "$TEMP_DIR"
        else
            echo "   - JetBrainsMono Nerd Font directory already exists."
        fi

        echo "🐳 Installing Oxker (Docker TUI)..."
        if ! command -v oxker &> /dev/null; then
            echo "   - Downloading and installing Oxker..."
            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ]; then
                OXKER_URL="https://github.com/mrjackwills/oxker/releases/latest/download/oxker_linux_x86_64.tar.gz"
            elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                OXKER_URL="https://github.com/mrjackwills/oxker/releases/latest/download/oxker_linux_aarch64.tar.gz"
            else
                OXKER_URL=""
            fi
            
            if [ -n "$OXKER_URL" ]; then
                TEMP_DIR=$(mktemp -d)
                if wget -qO "$TEMP_DIR/oxker.tar.gz" "$OXKER_URL"; then
                    tar -xzf "$TEMP_DIR/oxker.tar.gz" -C "$TEMP_DIR"
                    sudo mv "$TEMP_DIR/oxker" /usr/local/bin/
                    sudo chmod +x /usr/local/bin/oxker
                    echo "   ✅ Oxker installed."
                else
                    echo "   ⚠️ Failed to download Oxker."
                fi
                rm -rf "$TEMP_DIR"
            else
                echo "   ⚠️ Unsupported architecture for Oxker auto-install."
            fi
        else
            echo "   - Oxker is already installed."
        fi

        echo "⚠️  lazysql, vi-mongo, and ratisui are not in standard apt repos. Recommend installing Homebrew on Linux to get them."
    else
        echo "⚠️  Unsupported package manager. Please install 'alacritty' and 'tmux' manually."
    fi
fi

# 1.5 Install Zsh Tools & Plugins
echo "🔌 Installing Zsh Plugins..."
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "   - Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
else
    echo "   - zsh-syntax-highlighting already installed (pulling updates)..."
    git -C "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" pull || true
fi

if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo "   - Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
else
    echo "   - zsh-autosuggestions already installed (pulling updates)..."
    git -C "$ZSH_PLUGIN_DIR/zsh-autosuggestions" pull || true
fi

# 2. Config Linking
echo "🔗 Linking custom configurations..."

# Alacritty
mkdir -p "$CONFIG_DIR/alacritty"
# Backup existing Alacritty config if not a symlink
if [ -f "$CONFIG_DIR/alacritty/alacritty.toml" ] && [ ! -L "$CONFIG_DIR/alacritty/alacritty.toml" ]; then
    echo "   - Backing up existing alacritty.toml to alacritty.toml.bak"
    mv "$CONFIG_DIR/alacritty/alacritty.toml" "$CONFIG_DIR/alacritty/alacritty.toml.bak"
fi
# Link alacritty.toml (Using OS-specific config as main entry point)
if [ "$OS" = "Darwin" ]; then
    ln -sf "$REPO_DIR/config/alacritty/alacritty_macos.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
else
    ln -sf "$REPO_DIR/config/alacritty/alacritty_linux.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
fi

# Link imported common configs
ln -sf "$REPO_DIR/config/alacritty/alacritty_common.toml" "$CONFIG_DIR/alacritty/alacritty_common.toml"
ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"

# Tmux
mkdir -p "$CONFIG_DIR/tmux"
# Backup existing Tmux config if not a symlink
if [ -f "$CONFIG_DIR/tmux/tmux.conf" ] && [ ! -L "$CONFIG_DIR/tmux/tmux.conf" ]; then
    echo "   - Backing up existing tmux.conf to tmux.conf.bak"
    mv "$CONFIG_DIR/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf.bak"
fi
# Link tmux.conf
ln -sf "$REPO_DIR/config/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"

# Btop (Activity Monitor)
mkdir -p "$CONFIG_DIR/btop/themes"
ln -sf "$REPO_DIR/config/btop/btop.conf" "$CONFIG_DIR/btop/btop.conf"
ln -sf "$REPO_DIR/config/btop/themes/catppuccin_mocha.theme" "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme"

# 3. Tmux Plugin Manager
if [ ! -d "$TMUX_PLUGIN_DIR" ]; then
    echo "🔌 Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR"
else
    echo "✅ TPM already installed."
fi

# 4. Zsh Integration
ZSHRC="$HOME/.zshrc"
AUTO_TMUX_SNIPPET="$REPO_DIR/zsh/auto-tmux.zsh"
FEATURES_SNIPPET="$REPO_DIR/zsh/features.zsh"

echo "🐚 Configure Zsh..."

# Safely ensure .zshrc exists
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Backup existing .zshrc safely
cp "$ZSHRC" "${ZSHRC}.bak"

# 4.1 Auto-Tmux
if grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
    echo "   - Auto-tmux already configured."
else
    echo "   - Adding auto-tmux logic..."
    echo "" >> "$ZSHRC"
    cat "$AUTO_TMUX_SNIPPET" >> "$ZSHRC"
fi

# 4.2 Features (Highlighting, FZF History)
if grep -q "Termi Features" "$ZSHRC"; then
    echo "   - Top-grade features already configured."
else
    echo "   - Adding syntax highlighting & history search..."
    echo "" >> "$ZSHRC"
    echo "# Termi Features (Highlighting, Autosuggestions, FZF)" >> "$ZSHRC"
    echo "source \"$FEATURES_SNIPPET\"" >> "$ZSHRC"
fi

echo "✨ Setup complete! Restart your shell or launch Alacritty."
echo "💡 First run of Tmux (Press Ctrl+Space then I [shift+i] to install plugins)."
