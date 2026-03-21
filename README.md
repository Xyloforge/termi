# Termi: The Ultimate Minimalist Terminal
**Alacritty + Tmux + Zsh** — A unified, high-performance terminal environment that works identically on macOS, Linux, and Windows.

## 🚀 Installation

### 🍎 macOS & 🐧 Linux
Runs the universal setup script. Detects OS, installs dependencies (brew/apt/apk), links configs, and sets up Zsh.

1.  **Clone & Run:**
    ```bash
    git clone https://github.com/your-username/termi ~/.termi
    cd ~/.termi
    ./setup.sh install
    ```

2.  **Restart**: Close your current terminal and open **Alacritty**.

### 🪟 Windows

We provide two installation options on Windows depending on your workflow:

#### Option 1: Native PowerShell (Pure Windows)
Installs Alacritty, FZF, Zoxide, Bat, and Oh My Posh configured dynamically with Catppuccin Mocha to run perfectly in pure Windows PowerShell.

1.  Open **PowerShell as Administrator**.
2.  Clone the repo:
    ```powershell
    git clone git@github.com:Xyloforge/termi.git $HOME\termi
    cd $HOME\termi
    ```
3.  Set the execution policy so scripts can run:
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```
4.  Run the native installer:
    ```powershell
    .\setup.ps1 -install
    ```
4.  **Done**: Initial setup happens automatically. Open **Alacritty** from your Start Menu.

#### Option 2: Lightweight WSL (Alpine Linux)
Automated setup that seamlessly installs **WSL (Alpine Linux)** inside, but behaves like a native window running TMUX + Zsh + Linux tools.

1.  Open **PowerShell as Administrator**.
2.  Clone the repo:
    ```powershell
    git clone git@github.com:Xyloforge/termi.git $HOME\termi
    cd $HOME\termi
    ```
3.  Set the execution policy so scripts can run:
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```
4.  Run the WSL installer:
    ```powershell
    .\install_windows.ps1
    ```
4.  **Done**: Initial setup happens automatically inside the lightweight Linux environment. Open **Alacritty** from your Start Menu.

---

## ⌨️ Keybind Cheat Sheet

| Action | macOS | Windows / Linux |
| :--- | :--- | :--- |
| **New Tab** | `Cmd + T` | `Ctrl + T` |
| **Close Tab** | `Cmd + W` | `Alt + Shift + W` |
| **Split Right** | `Cmd + D` | `Alt + D` |
| **Split Down** | `Cmd + Shift + D` | `Alt + Shift + D` |
| **Navigate Panes** | `Cmd + H/J/K/L` | `Alt + H/J/K/L` |
| **Maximize Pane** | `Cmd + F` | `Alt + F` |
| **Rename Tab** | `Cmd + Shift + R` | `Alt + Shift + R` |
| **Copy** | `Cmd + C` | `Ctrl + Shift + C` |
| **Paste** | `Cmd + V` | `Ctrl + Shift + V` |

> **Note**: On Windows/Linux, we use `Alt` for window management to avoid conflicts with system shortcuts (like `Win+Arrow` or `Ctrl+C`).

## 🛠 Management
The `setup.sh` script is your central tool for managing the config.

- **Update Configs**: `./setup.sh update` (Pull changes & refresh symlinks)
- **Uninstall**: `./setup.sh uninstall` (Remove all configs & restore shell)
- **Install VS Code Theme**: `./setup.sh vscode` (Installs extensions)
