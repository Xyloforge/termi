#!/bin/bash

# Termi Centralized Management Script
# Unified interface for installing, updating, and managing Termi configuration.

set -e

# --- Global Variables ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins/tpm"
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
ZSHRC="$HOME/.zshrc"

# --- Helper Functions ---

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_warn() {
    echo "⚠️  $1"
}

log_error() {
    echo "❌ $1"
}

# --- Core Functions ---

install_core() {
    log_info "Starting Termi setup..."

    # 1. OS Detection & Dependency Installation
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        log_info "macOS detected."
        # Check if brew exists
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
        
        brew_install() {
            if ! brew list "$1" &>/dev/null; then
                log_info "Installing $1..."
                brew install "$1"
            else
                log_info "$1 is already installed."
            fi
        }
        
        brew_cask_install() {
            if ! brew list --cask "$1" &>/dev/null; then
                 log_info "Installing (cask) $1..."
                 brew install --cask "$1" || log_warn "Failed to install $1 (might be already installed manually)"
            else
                 log_info "$1 (cask) is already installed."
            fi
        }

        log_info "Installing packages..."
        # Install Alacritty, Fonts, FZF, Bat
        brew_cask_install alacritty
        brew_cask_install font-jetbrains-mono-nerd-font
        
        # Install Tmux & Tools
        brew_install tmux
        brew_install fzf
        brew_install bat
        brew_install btop

        # Fix "App can't be opened" error for Alacritty
        if [ -d "/Applications/Alacritty.app" ]; then
            log_info "Fixing macOS security quarantine for Alacritty..."
            sudo xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true
            codesign --force --deep --sign - /Applications/Alacritty.app 2>/dev/null || true
            log_success "Alacritty security fix applied."
        fi
    elif [ "$OS" = "Linux" ]; then
        log_info "Linux detected."
        # Check for apk (Alpine Linux)
        if command -v apk &> /dev/null; then
            log_info "Alpine Linux detected (apk)."
            # Create sudo shim if missing (Alpine often runs as root, or user without sudo)
            if ! command -v sudo &> /dev/null; then
                 log_warn "'sudo' not found. Assuming running as root."
                 alias sudo=""
            fi
            
            sudo apk update
            # Core tools
            sudo apk add tmux zsh git fzf bat
            # Optional: Alacritty (only if you plan to run GUI from WSL, mostly unused for headless)
            # sudo apk add alacritty || true 
            
            # Change default shell to zsh if not already
            if [[ "$SHELL" != *"/zsh" ]]; then
                 log_info "Changing default shell to zsh..."
                 sed -i "s|$USER:.*|$USER:/bin/zsh|g" /etc/passwd || true
            fi

        # Check for apt-get (Debian/Ubuntu/WSL)
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y alacritty tmux fzf bat
            
            # WSL 2 Check: Fonts often need to be installed in Windows, not just Linux subsys
            if grep -q "microsoft" /proc/version 2>/dev/null; then
                 log_warn "WSL detected: You must install 'JetBrainsMono Nerd Font' on Windows manually!"
            else
                 log_warn "Please ensure 'JetBrainsMono Nerd Font' is installed manually on your system."
            fi
        else
            log_warn "Unsupported package manager (not apt). Please install 'alacritty', 'tmux', 'fzf', 'bat' manually."
        fi
    fi

    # 2. Install Zsh Tools & Plugins
    log_info "Installing Zsh Plugins..."
    mkdir -p "$ZSH_PLUGIN_DIR"
    
    if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        log_info "Cloning zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting already installed (pulling updates)..."
        git -C "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" pull || true
    fi
    
    if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
        log_info "Cloning zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed (pulling updates)..."
        git -C "$ZSH_PLUGIN_DIR/zsh-autosuggestions" pull || true
    fi

    # 3. Config Linking
    log_info "Linking custom configurations..."
    
    # Alacritty
    # Alacritty
    mkdir -p "$CONFIG_DIR/alacritty"
    
    # Link Common & Theme
    ln -sf "$REPO_DIR/config/alacritty/alacritty_common.toml" "$CONFIG_DIR/alacritty/alacritty_common.toml"
    ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"

    # Link Platform Specific Config
    if [ "$OS" = "Darwin" ]; then
        log_info "Linking macOS Alacritty config..."
        ln -sf "$REPO_DIR/config/alacritty/alacritty_macos.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    else
        log_info "Linking Linux/WSL Alacritty config..."
        ln -sf "$REPO_DIR/config/alacritty/alacritty_linux.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    fi
    
    # Tmux
    mkdir -p "$CONFIG_DIR/tmux"
    ln -sf "$REPO_DIR/config/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
    
    # Btop
    mkdir -p "$CONFIG_DIR/btop/themes"
    ln -sf "$REPO_DIR/config/btop/btop.conf" "$CONFIG_DIR/btop/btop.conf"
    ln -sf "$REPO_DIR/config/btop/themes/catppuccin_mocha.theme" "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme"

    # 4. Tmux Plugin Manager
    if [ ! -d "$TMUX_PLUGIN_DIR" ]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR"
    else
        log_success "TPM already installed."
    fi

    # 5. Zsh Integration
    log_info "Configuring Zsh..."
    
    AUTO_TMUX_SNIPPET="$REPO_DIR/zsh/auto-tmux.zsh"
    FEATURES_SNIPPET="$REPO_DIR/zsh/features.zsh"
    
    # Auto-Tmux
    if grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
        log_info "Auto-tmux already configured."
    else
        log_info "Adding auto-tmux logic..."
        echo "" >> "$ZSHRC"
        cat "$AUTO_TMUX_SNIPPET" >> "$ZSHRC"
    fi
    
    # Features
    if grep -q "Termi Features" "$ZSHRC"; then
        log_info "Top-grade features already configured."
    else
        log_info "Adding syntax highlighting & history search..."
        echo "" >> "$ZSHRC"
        echo "# Termi Features (Highlighting, Autosuggestions, FZF)" >> "$ZSHRC"
        echo "source \"$FEATURES_SNIPPET\"" >> "$ZSHRC"
    fi

    log_success "Setup complete! Restart your shell or launch Alacritty."
    log_info "First run of Tmux: Press Ctrl+Space then I [shift+i] to install plugins."
}

uninstall_core() {
    log_info "Starting uninstallation..."

    # 1. Remove Configuration Links
    log_info "Removing configurations..."
    rm -f "$CONFIG_DIR/alacritty/alacritty.toml"
    rm -f "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"
    rm -f "$CONFIG_DIR/tmux/tmux.conf"
    rm -f "$CONFIG_DIR/btop/btop.conf"
    rm -f "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme"

    rmdir "$CONFIG_DIR/alacritty" 2>/dev/null || true
    rmdir "$CONFIG_DIR/tmux" 2>/dev/null || true
    rmdir "$CONFIG_DIR/btop/themes" 2>/dev/null || true

    # 2. Remove Tmux Plugin Manager
    if [ -d "$TMUX_PLUGIN_DIR" ]; then
        log_info "Removing Tmux Plugin Manager..."
        rm -rf "$TMUX_PLUGIN_DIR"
    fi

    # 3. Clean .zshrc
    if grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
        log_info "Removing Auto-Tmux snippet from $ZSHRC..."
        cp "$ZSHRC" "${ZSHRC}.bak"
        log_info "(Backup saved to ${ZSHRC}.bak)"
        
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' '/# Auto-Tmux Configuration (Added by Install Script)/,+8d' "$ZSHRC"
        else
            sed -i '/# Auto-Tmux Configuration (Added by Install Script)/,+8d' "$ZSHRC"
        fi
        
        # Also try to remove the features block if we added it
        if grep -q "Termi Features" "$ZSHRC"; then
             log_info "Removing Termi Features snippet..."
             if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' '/# Termi Features (Highlighting, Autosuggestions, FZF)/,+2d' "$ZSHRC"
             else
                sed -i '/# Termi Features (Highlighting, Autosuggestions, FZF)/,+2d' "$ZSHRC"
             fi
        fi
    fi

    log_success "Configurations removed."

    # 4. Uninstall Packages (Interactive)
    read -p "❓ Do you want to uninstall Alacritty, Tmux, and the Nerd Font? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        OS="$(uname -s)"
        if [ "$OS" = "Darwin" ]; then
            log_info "Uninstalling packages via Homebrew..."
            brew uninstall --cask alacritty font-jetbrains-mono-nerd-font
            brew uninstall tmux
        elif [ "$OS" = "Linux" ]; then
            log_info "Uninstalling packages..."
            if command -v apk &> /dev/null; then
                 sudo apk del alacritty tmux fzf bat
            elif command -v apt-get &> /dev/null; then
                sudo apt-get remove -y alacritty tmux
            fi
        fi
        log_success "Packages uninstalled."
    else
        log_info "Packages kept installed."
    fi

    log_success "Uninstallation complete."
}

update_core() {
    log_info "Updating Termi configuration..."

    # 1. Update Symlinks
    log_info "Refreshing symlinks..."
    mkdir -p "$CONFIG_DIR/alacritty" "$CONFIG_DIR/tmux" "$CONFIG_DIR/btop/themes"

    ln -sf "$REPO_DIR/config/alacritty/alacritty_common.toml" "$CONFIG_DIR/alacritty/alacritty_common.toml"
    ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"
    
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        ln -sf "$REPO_DIR/config/alacritty/alacritty_macos.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    else
        ln -sf "$REPO_DIR/config/alacritty/alacritty_linux.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    fi
    ln -sf "$REPO_DIR/config/tmux/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
    ln -sf "$REPO_DIR/config/btop/btop.conf" "$CONFIG_DIR/btop/btop.conf"
    ln -sf "$REPO_DIR/config/btop/themes/catppuccin_mocha.theme" "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme"

    # 2. Add Auto-Tmux to Zsh (if missing)
    AUTO_TMUX_SNIPPET="$REPO_DIR/zsh/auto-tmux.zsh"
    if ! grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
        log_info "Adding missing auto-tmux logic to $ZSHRC..."
        echo "" >> "$ZSHRC"
        cat "$AUTO_TMUX_SNIPPET" >> "$ZSHRC"
    fi

    # 3. Reload Alacritty
    if [ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]; then
        touch "$CONFIG_DIR/alacritty/alacritty.toml"
        log_success "Alacritty config refreshed."
    fi

    # 4. Reload Tmux
    if command -v tmux &> /dev/null && pgrep tmux > /dev/null; then
        log_info "Reloading active Tmux session..."
        tmux source-file "$CONFIG_DIR/tmux/tmux.conf" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_success "Tmux reloaded."
        else
            log_warn "Tmux reload check failed. Check syntax or logs."
        fi
        
        if [ -d "$TMUX_PLUGIN_DIR" ]; then
             log_info "Note: To update Tmux plugins, press Prefix + U inside Tmux."
        fi
    else
        log_info "Tmux not running; changes will apply on next start."
    fi

    log_success "Update complete."
}

install_vscode() {
    # Check if 'code' command exists
    if ! command -v code &> /dev/null; then
        log_error "VS Code 'code' command not found."
        log_info "Please enable it in VS Code (Cmd+Shift+P -> Shell Command: Install 'code' command in PATH)."
        return 1
    fi

    log_info "Installing VS Code Extensions..."
    # Install Catppuccin Theme
    code --install-extension Catppuccin.catppuccin-vsc
    # Install Vim (Optional)
    # code --install-extension vscodevim.vim
    # Install Icons
    code --install-extension PKief.material-icon-theme

    log_success "VS Code extensions installed."
    log_info "To apply the settings: Copy contents of config/vscode/settings.json to your user settings."
}

# --- Main CLI ---

usage() {
    echo "Usage: $0 {install|uninstall|update|vscode|help}"
    echo
    echo "Commands:"
    echo "  install    Full setup (App installation, config linking, shell setup)"
    echo "  uninstall  Remove configurations and optionally uninstall apps"
    echo "  update     Refresh configurations and symlinks"
    echo "  vscode     Install VS Code extensions (Theme, Icons)"
    echo "  help       Show this help message"
}

case "$1" in
    install)
        install_core
        ;;
    uninstall)
        uninstall_core
        ;;
    update)
        update_core
        ;;
    vscode)
        install_vscode
        ;;
    help|*)
        usage
        ;;
esac
