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

log_tmux_reminder() {
    local RED='\033[1;31m'
    local RESET='\033[0m'
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║                                                          ║${RESET}"
    echo -e "${RED}║  ACTION REQUIRED — Tmux plugins not installed yet!       ║${RESET}"
    echo -e "${RED}║                                                          ║${RESET}"
    echo -e "${RED}║  Inside Tmux, press:  Ctrl+Space  then  Shift+I         ║${RESET}"
    echo -e "${RED}║  This installs all plugins on first run.                 ║${RESET}"
    echo -e "${RED}║                                                          ║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# --- Per-User Config Setup ---
# Sets up symlinks, zsh plugins, tmux, and zshrc for a given user.
# Usage: setup_user_config <username> <home_dir>
setup_user_config() {
    local target_user="$1"
    local target_home="$2"
    local target_config="$target_home/.config"
    local target_zshrc="$target_home/.zshrc"
    local target_zsh_plugin_dir="$target_home/.zsh/plugins"
    local target_tmux_plugin_dir="$target_home/.tmux/plugins/tpm"

    log_info "Configuring for user: $target_user ($target_home)"

    # 1. Zsh Plugins
    mkdir -p "$target_zsh_plugin_dir"

    if [ ! -d "$target_zsh_plugin_dir/zsh-syntax-highlighting" ]; then
        log_info "Cloning zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$target_zsh_plugin_dir/zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting already installed (pulling updates)..."
        git -C "$target_zsh_plugin_dir/zsh-syntax-highlighting" pull || true
    fi

    if [ ! -d "$target_zsh_plugin_dir/zsh-autosuggestions" ]; then
        log_info "Cloning zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$target_zsh_plugin_dir/zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed (pulling updates)..."
        git -C "$target_zsh_plugin_dir/zsh-autosuggestions" pull || true
    fi

    if [ ! -d "$target_zsh_plugin_dir/powerlevel10k" ]; then
        log_info "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$target_zsh_plugin_dir/powerlevel10k"
    else
        log_info "Powerlevel10k already installed (pulling updates)..."
        git -C "$target_zsh_plugin_dir/powerlevel10k" pull || true
    fi

    # 2. Config Symlinks

    # p10k
    ln -sf "$REPO_DIR/config/zsh/p10k.zsh" "$target_home/.p10k.zsh"

    # Alacritty
    mkdir -p "$target_config/alacritty"
    ln -sf "$REPO_DIR/config/alacritty/alacritty_common.toml" "$target_config/alacritty/alacritty_common.toml"
    ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$target_config/alacritty/catppuccin-mocha.toml"
    if [ "$OS" = "Darwin" ]; then
        ln -sf "$REPO_DIR/config/alacritty/alacritty_macos.toml" "$target_config/alacritty/alacritty.toml"
    else
        ln -sf "$REPO_DIR/config/alacritty/alacritty_linux.toml" "$target_config/alacritty/alacritty.toml"
    fi

    # Tmux
    mkdir -p "$target_config/tmux"
    ln -sf "$REPO_DIR/config/tmux/tmux.conf"        "$target_config/tmux/tmux.conf"
    ln -sf "$REPO_DIR/config/tmux/auto_resize.sh"   "$target_config/tmux/auto_resize.sh"
    ln -sf "$REPO_DIR/config/tmux/log_grabber.sh"   "$target_config/tmux/log_grabber.sh"
    ln -sf "$REPO_DIR/config/tmux/yank_preview.sh"  "$target_config/tmux/yank_preview.sh"
    ln -sf "$REPO_DIR/config/tmux/open_in_editor.sh" "$target_config/tmux/open_in_editor.sh"
    ln -sf "$REPO_DIR/config/tmux/pane_viewer.sh"   "$target_config/tmux/pane_viewer.sh"

    # Btop
    mkdir -p "$target_config/btop/themes"
    ln -sf "$REPO_DIR/config/btop/btop.conf"                        "$target_config/btop/btop.conf"
    ln -sf "$REPO_DIR/config/btop/themes/catppuccin_mocha.theme"    "$target_config/btop/themes/catppuccin_mocha.theme"

    # Neovim
    if [ "$INSTALL_NEOVIM" = true ]; then
        log_info "Linking Neovim config for $target_user..."
        if [ -d "$target_config/nvim" ] && [ ! -L "$target_config/nvim" ]; then
            log_info "Backing up existing nvim config to nvim.bak..."
            mv "$target_config/nvim" "$target_config/nvim.bak"
        fi
        ln -sfn "$REPO_DIR/config/nvim" "$target_config/nvim"
        log_success "Neovim config linked for $target_user."
    fi

    # Fix ownership if running as root and setting up a different user
    if [ "$(id -u)" = "0" ] && [ "$target_user" != "root" ]; then
        chown -h "$target_user:$target_user" \
            "$target_home/.p10k.zsh" \
            "$target_config/alacritty/alacritty.toml" \
            "$target_config/alacritty/alacritty_common.toml" \
            "$target_config/alacritty/catppuccin-mocha.toml" \
            "$target_config/tmux/tmux.conf" \
            "$target_config/tmux/auto_resize.sh" \
            "$target_config/tmux/log_grabber.sh" \
            "$target_config/tmux/yank_preview.sh" \
            "$target_config/tmux/open_in_editor.sh" \
            "$target_config/tmux/pane_viewer.sh" \
            "$target_config/btop/btop.conf" \
            "$target_config/btop/themes/catppuccin_mocha.theme" 2>/dev/null || true
        chown -R "$target_user:$target_user" "$target_zsh_plugin_dir" 2>/dev/null || true
    fi

    # 3. Tmux Plugin Manager
    if [ ! -d "$target_tmux_plugin_dir" ]; then
        log_info "Installing Tmux Plugin Manager for $target_user..."
        git clone https://github.com/tmux-plugins/tpm "$target_tmux_plugin_dir"
        if [ "$(id -u)" = "0" ] && [ "$target_user" != "root" ]; then
            chown -R "$target_user:$target_user" "$target_home/.tmux" 2>/dev/null || true
        fi
    else
        log_success "TPM already installed for $target_user."
    fi

    # 4. Zsh Integration
    log_info "Configuring Zsh for $target_user..."
    [ -f "$target_zshrc" ] || touch "$target_zshrc"

    # Auto-Tmux
    if grep -q "Auto-Tmux Configuration" "$target_zshrc"; then
        log_info "Auto-tmux already configured for $target_user."
    else
        log_info "Adding auto-tmux logic..."
        echo "" >> "$target_zshrc"
        cat "$REPO_DIR/zsh/auto-tmux.zsh" >> "$target_zshrc"
    fi

    # Features
    if grep -q "Termi Features" "$target_zshrc"; then
        log_info "Features already configured for $target_user."
    else
        log_info "Adding syntax highlighting & history search..."
        echo "" >> "$target_zshrc"
        echo "# Termi Features (Highlighting, Autosuggestions, FZF)" >> "$target_zshrc"
        echo "source \"$REPO_DIR/zsh/features.zsh\"" >> "$target_zshrc"
    fi

    if [ "$(id -u)" = "0" ] && [ "$target_user" != "root" ]; then
        chown "$target_user:$target_user" "$target_zshrc" 2>/dev/null || true
    fi

    # 5. Set default shell to zsh
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null)"
    if [ -z "$zsh_path" ]; then
        log_warn "zsh not found — skipping shell change for $target_user. Install zsh first."
    else
        local current_shell
        current_shell="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7)"
        if [[ "$current_shell" == "$zsh_path" ]]; then
            log_info "Default shell is already zsh for $target_user."
        else
            log_info "Changing default shell to zsh for $target_user..."
            if [ "$(id -u)" = "0" ]; then
                usermod -s "$zsh_path" "$target_user" 2>/dev/null \
                    || chsh -s "$zsh_path" "$target_user" 2>/dev/null \
                    || log_warn "Could not change shell for $target_user. Run manually: chsh -s $zsh_path $target_user"
            else
                chsh -s "$zsh_path" \
                    || log_warn "Could not change shell. Run manually: chsh -s $zsh_path"
            fi
            log_success "Default shell set to zsh for $target_user. Takes effect on next login."
        fi
    fi

    log_success "Setup complete for user: $target_user"
}

# --- Ensure Public Install Location ---
# If REPO_DIR is inside a user home directory, offer to copy it to /opt/termi
# so all users can read and symlink to it.
ensure_public_install() {
    local public_dir="/opt/termi"

    # Already in a system-wide location — nothing to do
    if [[ "$REPO_DIR" == /opt/* ]] || [[ "$REPO_DIR" == /usr/* ]] || [[ "$REPO_DIR" == /bin/* ]] || [[ "$REPO_DIR" == /srv/* ]]; then
        return
    fi

    log_warn "Termi is at '$REPO_DIR' — not a shared system path."
    log_info "For all users to symlink configs, it should be at a public location like '$public_dir'."
    read -r -p "Copy to '$public_dir' now? [Y/n] " _move_reply
    if [[ "$_move_reply" =~ ^[Nn]$ ]]; then
        log_warn "Keeping at '$REPO_DIR'. Make sure all users can read it: chmod -R a+rX '$REPO_DIR'"
        return
    fi

    if [ -d "$public_dir" ]; then
        log_warn "'$public_dir' already exists."
        read -r -p "Overwrite it? [y/N] " _overwrite_reply
        if [[ ! "$_overwrite_reply" =~ ^[Yy]$ ]]; then
            log_info "Using existing '$public_dir'."
            REPO_DIR="$public_dir"
            return
        fi
        rm -rf "$public_dir"
    fi

    cp -r "$REPO_DIR" "$public_dir"
    chmod -R 755 "$public_dir"
    log_success "Copied to $public_dir (world-readable)."
    log_info "You can delete the original at '$REPO_DIR' once you've verified everything works."
    REPO_DIR="$public_dir"
}

# --- Core Functions ---

install_core() {
    log_info "Starting Termi setup..."

    # Optional: Neovim
    INSTALL_NEOVIM=false
    if command -v nvim &> /dev/null; then
        log_info "Neovim already installed — skipping prompt."
        INSTALL_NEOVIM=true
    else
        read -r -p "Install Neovim? [y/N] " _nvim_reply
        if [[ "$_nvim_reply" =~ ^[Yy]$ ]]; then
            INSTALL_NEOVIM=true
        fi
    fi

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
        brew_cask_install alacritty
        brew_cask_install font-jetbrains-mono-nerd-font

        # Taps for extra tools
        brew tap kopecmaciej/vi-mongo 2>/dev/null || true
        brew tap honhimW/tap 2>/dev/null || true

        brew_install tmux
        brew_install fzf
        brew_install bat
        brew_install btop
        brew_install zoxide
        brew_install lazysql
        brew_install vi-mongo
        brew_install ratisui
        brew_install oxker

        if [ "$INSTALL_NEOVIM" = true ]; then
            brew_install neovim
        fi

        # Fix "App can't be opened" error for Alacritty
        if [ -d "/Applications/Alacritty.app" ]; then
            log_info "Fixing macOS security quarantine for Alacritty..."
            sudo xattr -r -d com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true
            codesign --force --deep --sign - /Applications/Alacritty.app 2>/dev/null || true
            log_success "Alacritty security fix applied."
        fi

        # macOS is always single-user (current user)
        setup_user_config "$USER" "$HOME"

    elif [ "$OS" = "Linux" ]; then
        log_info "Linux detected."
        # Check for apk (Alpine Linux)
        if command -v apk &> /dev/null; then
            log_info "Alpine Linux detected (apk)."
            # Create sudo shim if missing (Alpine often runs as root, or user without sudo)
            if ! command -v sudo &> /dev/null; then
                 log_warn "'sudo' not found. Assuming running as root."
                 sudo() { "$@"; }
            fi

            sudo apk update
            # Core tools
            sudo apk add tmux zsh git fzf bat btop zoxide wget tar unzip lsof fontconfig
            if [ "$INSTALL_NEOVIM" = true ]; then
                sudo apk add neovim
            fi
            # Optional: Alacritty (only if you plan to run GUI from WSL, mostly unused for headless)
            # sudo apk add alacritty || true

            log_info "Installing Oxker (Docker TUI)..."
            if ! command -v oxker &> /dev/null; then
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
                        log_success "Oxker installed."
                    else
                        log_warn "Failed to download Oxker."
                    fi
                    rm -rf "$TEMP_DIR"
                else
                    log_warn "Unsupported architecture for Oxker auto-install."
                fi
            else
                log_info "Oxker is already installed."
            fi

            log_info "Installing JetBrainsMono Nerd Font..."
            FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
            if [ ! -d "$FONT_DIR" ]; then
                mkdir -p "$FONT_DIR"
                TEMP_DIR=$(mktemp -d)
                if wget -qO "$TEMP_DIR/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
                    unzip -qo "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"
                    fc-cache -fv &> /dev/null
                    log_success "JetBrainsMono Nerd Font installed."
                else
                    log_warn "Failed to download JetBrainsMono Nerd Font. Please install manually."
                fi
                rm -rf "$TEMP_DIR"
            else
                log_info "JetBrainsMono Nerd Font already installed."
            fi

            log_warn "lazysql, vi-mongo, and ratisui are not in Alpine repos. Install Homebrew on Linux to get them: https://brew.sh"

            # Change default shell to zsh if not already
            if [[ "$SHELL" != *"/zsh" ]]; then
                 log_info "Changing default shell to zsh..."
                 sed -i "s|$USER:.*|$USER:/bin/zsh|g" /etc/passwd || true
            fi

        # Check for apt-get (Debian/Ubuntu/WSL)
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y tmux fzf bat btop zoxide wget tar unzip fontconfig lsof
            if [ "$INSTALL_NEOVIM" = true ]; then
                sudo apt-get install -y neovim
            fi
            # Alacritty may not be in all apt repos — install if available, skip otherwise
            sudo apt-get install -y alacritty 2>/dev/null || log_warn "Alacritty not found in apt. Install manually or via snap: 'sudo snap install alacritty --classic'"

            log_info "Installing JetBrainsMono Nerd Font..."
            FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
            if [ ! -d "$FONT_DIR" ]; then
                mkdir -p "$FONT_DIR"
                TEMP_DIR=$(mktemp -d)
                if wget -qO "$TEMP_DIR/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
                    unzip -qo "$TEMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"
                    fc-cache -fv &> /dev/null
                    log_success "JetBrainsMono Nerd Font installed."
                else
                    log_warn "Failed to download JetBrainsMono Nerd Font. Please install manually."
                fi
                rm -rf "$TEMP_DIR"
            else
                log_info "JetBrainsMono Nerd Font already installed."
            fi

            log_info "Installing Oxker (Docker TUI)..."
            if ! command -v oxker &> /dev/null; then
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
                        log_success "Oxker installed."
                    else
                        log_warn "Failed to download Oxker."
                    fi
                    rm -rf "$TEMP_DIR"
                else
                    log_warn "Unsupported architecture for Oxker auto-install."
                fi
            else
                log_info "Oxker is already installed."
            fi

            # WSL 2: fonts need to be installed in Windows, not the Linux subsystem
            if grep -q "microsoft" /proc/version 2>/dev/null; then
                log_warn "WSL detected: Install 'JetBrainsMono Nerd Font' on Windows for Alacritty font rendering."
            fi

            log_warn "lazysql, vi-mongo, and ratisui are not in standard apt repos. Install Homebrew on Linux to get them: https://brew.sh"
        else
            log_warn "Unsupported package manager (not apt/apk). Please install 'alacritty', 'tmux', 'fzf', 'bat' manually."
        fi

        # 2. User scope — current user only, or all users on this system
        echo ""
        log_info "Who should this configuration apply to?"
        echo "  [1] Current user only ($USER)"
        echo "  [2] All users on this system"
        read -r -p "Choice [1]: " _scope_reply

        if [[ "$_scope_reply" == "2" ]]; then
            ensure_public_install
            log_info "Setting up configuration for all users..."

            # Root
            setup_user_config "root" "/root"

            # All home directory users
            for user_home in /home/*/; do
                [ -d "$user_home" ] || continue
                u=$(basename "$user_home")
                setup_user_config "$u" "$user_home"
            done
        else
            setup_user_config "$USER" "$HOME"
        fi
    fi

    log_success "Setup complete! Restart your shell or launch Alacritty."
    log_tmux_reminder
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

    # 0. Pull latest changes from GitHub
    log_info "Pulling latest changes from GitHub..."
    if git -C "$REPO_DIR" pull; then
        log_success "Repository updated."
    else
        log_warn "git pull failed. Continuing with local files..."
    fi

    # 1. Update Symlinks
    log_info "Refreshing symlinks..."
    mkdir -p "$CONFIG_DIR/alacritty" "$CONFIG_DIR/tmux" "$CONFIG_DIR/btop/themes"

    ln -sf "$REPO_DIR/config/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    ln -sf "$REPO_DIR/config/alacritty/alacritty_common.toml" "$CONFIG_DIR/alacritty/alacritty_common.toml"
    ln -sf "$REPO_DIR/config/alacritty/catppuccin-mocha.toml" "$CONFIG_DIR/alacritty/catppuccin-mocha.toml"

    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        ln -sf "$REPO_DIR/config/alacritty/alacritty_macos.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    else
        ln -sf "$REPO_DIR/config/alacritty/alacritty_linux.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    fi
    ln -sf "$REPO_DIR/config/tmux/tmux.conf"         "$CONFIG_DIR/tmux/tmux.conf"
    ln -sf "$REPO_DIR/config/tmux/auto_resize.sh"    "$CONFIG_DIR/tmux/auto_resize.sh"
    ln -sf "$REPO_DIR/config/tmux/log_grabber.sh"    "$CONFIG_DIR/tmux/log_grabber.sh"
    ln -sf "$REPO_DIR/config/tmux/yank_preview.sh"   "$CONFIG_DIR/tmux/yank_preview.sh"
    ln -sf "$REPO_DIR/config/tmux/open_in_editor.sh" "$CONFIG_DIR/tmux/open_in_editor.sh"
    ln -sf "$REPO_DIR/config/tmux/pane_viewer.sh"    "$CONFIG_DIR/tmux/pane_viewer.sh"
    ln -sf "$REPO_DIR/config/btop/btop.conf"         "$CONFIG_DIR/btop/btop.conf"
    ln -sf "$REPO_DIR/config/btop/themes/catppuccin_mocha.theme" "$CONFIG_DIR/btop/themes/catppuccin_mocha.theme"

    # 2. Add Auto-Tmux to Zsh (if missing)
    if ! grep -q "Auto-Tmux Configuration" "$ZSHRC"; then
        log_info "Adding missing auto-tmux logic to $ZSHRC..."
        echo "" >> "$ZSHRC"
        cat "$REPO_DIR/zsh/auto-tmux.zsh" >> "$ZSHRC"
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
