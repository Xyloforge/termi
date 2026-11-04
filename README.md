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
| **New Tmux Window** | `Cmd + T` | `Alt + Y` |
| **New Tmux Session** | `Cmd + Shift + T` | `Ctrl+Space` then `T` |
| **New Alacritty Tab** | `Cmd + Y` | — |
| **Close Pane** | `Cmd + W` | `Alt + W` |
| **Close Tmux Window** | `Cmd + Shift + W` | `Alt + Shift + W` |
| **Split Right** | `Cmd + D` | `Alt + D` |
| **Split Down** | `Cmd + Shift + D` | `Alt + Shift + D` |
| **Navigate Panes** | `Cmd + H/J/K/L` | `Alt + H/J/K/L` |
| **Maximize Pane** | `Cmd + F` | `Alt + F` |
| **Rename Tmux Window** | `Cmd + Shift + R` | `Alt + Shift + R` |
| **Copy** | `Cmd + C` | `Ctrl + Shift + C` |
| **Paste** | `Cmd + V` | `Ctrl + Shift + V` |

Tmux windows are workspaces inside the current terminal. New tmux windows and
splits use the focused pane's current directory, including after `cd`. On macOS,
the red close button closes a native Alacritty window or tab and leaves tmux work
running.

New session prompts for a name, then switches into the session in the focused
pane's current directory. Press `Ctrl+C` to cancel the prompt.

> **Note**: On Windows/Linux, we use `Alt` for window management to avoid conflicts with system shortcuts (like `Win+Arrow` or `Ctrl+C`).

## 🛠 Management
The `setup.sh` script is your central tool for managing the config.

- **Update Configs**: `./setup.sh update` (Pull changes & refresh symlinks)
- **Uninstall**: `./setup.sh uninstall` (Remove all configs & restore shell)
- **Install VS Code Theme**: `./setup.sh vscode` (Installs extensions)


## Session recovery and local upgrades

Apply local changes with `./setup.sh reload`. This refreshes helper links,
backs up `.zshrc`, replaces the old copied auto-tmux block with a managed
`source`, and reloads tmux. It does not pull Git changes or install packages.
Python 3.8+ is required on macOS/Linux/WSL; the installer includes Python.

Opening another terminal attaches to recent live work, regardless of its launch
directory. On a fresh server, recovery waits for the first session/client and
runs once. Reloading the configuration does not restore an older snapshot.

Layout changes trigger a checkpoint after a one-second coalescing delay. Closing
a terminal client also requests a save. Continuum adds a one-minute periodic
save while the status bar is running. Saves and restores share a crash-released
file lock. New layout and scrollback files are validated and flushed in a
separate generation before `last` is atomically replaced. Failed saves leave the
previous checkpoint usable; failed restores pause saving to protect the source.
The latest 20 completed generations are retained, along with existing legacy
snapshots. Named tmux servers have separate default storage.

`Cmd+Z` toggles zoom on the focused pane. `Cmd+A` switches to the previous
window, including across sessions, with separate history for each terminal
client. Auto-resize respects manual zoom. These shortcuts have different jobs.

- Save now: **Ctrl+Space, then Ctrl+S**. This waits for an in-progress save.
- Restore manually: **Ctrl+Space, then Ctrl+R**.
- Inspect the latest error: `tmux show-option -gqv @termi-session-error`.
- Locate checkpoints: `tmux show-option -gqv @termi-state-dir`.
- Inspect last successful save (Unix time): `tmux show-option -gqv @termi-last-save`.

A sudden power loss can still lose changes made after the last completed
checkpoint. Before restarting deliberately, use Save now and wait for it to
finish. Recovery restores tmux layouts, directories and scrollback; it does not
preserve live process memory, SSH connections, or every application's state.

Run regressions with `python3 -m unittest discover -s tests -v`. Tests use
private tmux sockets and temporary snapshot directories. The restart tests use
an installed tmux-resurrect plugin (or `TERMI_RESURRECT_PATH`); the full startup
test also requires TPM at `~/.tmux/plugins/tpm`.
