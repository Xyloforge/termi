# Termi Migration Kit

This repository migrates your terminal workflow from WezTerm to **Alacritty + Tmux**, maintaining your existing shortcuts and design.

## Features
- **Alacritty**: GPU-accelerated, Catppuccin Mocha theme, JetBrains Mono Nerd Font.
- **Tmux**: `Ctrl+Space` prefix, mouse support, persistence (resurrect/continuum).
- **Keybinds**: WezTerm-like shortcuts (`Cmd+D` split, `Cmd+W` close, `Cmd+H/J/K/L` resize) mapped to Tmux.

## Installation

### 1. Clone
Clone this repo to a permanent location (e.g., `~/dotfiles` or `~/termi-migration`).
```bash
# If you haven't already:
# git clone <your-repo-url> ~/termi-migration
# cd ~/termi-migration
```

### 2. Install
Run the installer. It backs up nothing, but uses symlinks, so your original files (if in other paths) are safe.

**Supported OS:**
- **macOS**: Installs via Homebrew.
- **Linux (Debian/Ubuntu)**: Installs via `apt`.
- **Windows (WSL2)**: Treated as Linux. Ensure you are running this inside your WSL terminal (Ubuntu recommended).

```bash
chmod +x install.sh
./install.sh
```

### 3. Finalize Tmux
Open Alacritty (which will auto-start Tmux).
Press `Ctrl + Space` then `I` (Shift + i) to verify and install Tmux plugins.

## Keybind Cheat Sheet
| Action | Keybind (Mac) | Equivalent Tmux |
|--------|---------------|-----------------|
| Split Side-by-Side (Horiz) | `Cmd + D` | `Prefix + %` |
| Split Top-Bottom (Vert) | `Cmd + Shift + D` | `Prefix + "` |
| New Window | `Cmd + Y` | `Prefix + c` |
| Close Pane | `Cmd + W` | `Prefix + x` |
| Close Window | `Cmd + Shift + W` | `Prefix + &` |
| Resize Pane | `Cmd + H/J/K/L` | `Prefix + H/J/K/L` |
| Window Selector | `Cmd + P` | `Prefix + w` |
| Rename Tab | `Cmd + Shift + R` | `Prefix + ,` |

## Troubleshooting
- **Fonts**: If icons don't show up, ensure `JetBrainsMono Nerd Font` is installed. The script tries to install it via homebrew.
- **Tmux Colors**: If colors look dull, ensure Alacritty is setting `TERM` to `xterm-256color` (default in this config).
- **"Alacritty can't be opened"**: This is normal for open-source apps on macOS. Fix it by running:
  ```bash
  sudo xattr -r -d com.apple.quarantine /Applications/Alacritty.app
  ```
