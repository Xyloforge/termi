# Termi Keybind Cheatsheet

Since we mapped Alacritty keys to Tmux, you have two ways to do everything:

1.  **MacOS Style**: Using `Cmd` keys (Fastest ⚡️)
2.  **Tmux Style**: Using `Ctrl+Space` prefix (Classic 🎹)

## 🪟 Windows & Panes

| Action                 | MacOS Shortcut (Alacritty) | Tmux Shortcut         |
| :--------------------- | :------------------------- | :-------------------- |
| **New Window**         | `Cmd + Y`                  | `Ctrl+Space` then `c` |
| **Split Right**        | `Cmd + D`                  | `Ctrl+Space` then `%` |
| **Split Down**         | `Cmd + Shift + D`          | `Ctrl+Space` then `"` |
| **Close Pane**         | `Cmd + W`                  | `Ctrl+Space` then `x` |
| **Close Window**       | `Cmd + Shift + W`          | `Ctrl+Space` then `&` |
| **Next Window**        | _(none)_                   | `Ctrl+Space` then `n` |
| **Previous Window**    | _(none)_                   | `Ctrl+Space` then `p` |
| **List Windows/Panes** | `Cmd + P`                  | `Ctrl+Space` then `w` |
| **List Sessions**      | `Cmd + Shift + P`          | `Ctrl+Space` then `s` |
| **Show Pane Numbers**  | `Cmd + O`                  | `Ctrl+Space` then `q` |
| **Rename Window**      | `Cmd + Shift + R`          | `Ctrl+Space` then `,` |

## 🧭 Navigation

| Action               | MacOS Shortcut | Tmux Shortcut                                 |
| :------------------- | :------------- | :-------------------------------------------- |
| **Move Focus Left**  | `Cmd + H`      | `Ctrl+Space` then `h`                         |
| **Move Focus Down**  | `Cmd + J`      | `Ctrl+Space` then `j`                         |
| **Move Focus Up**    | `Cmd + K`      | `Ctrl+Space` then `k`                         |
| **Move Focus Right** | `Cmd + L`      | `Ctrl+Space` then `l`                         |
| **Fullscreen**       | `Cmd + N`      | `Ctrl+Space` then `z` (Zoom pane)             |
| **Auto Resize Mode** | _(none)_       | `Ctrl+Space` then `a` (Auto-zoom small panes) |

## 🛠 Session Management

| Action              | Shortcut                                           |
| :------------------ | :------------------------------------------------- |
| **Detach Session**  | `Ctrl+Space` then `d`                              |
| **Rename Session**  | `Ctrl+Space` then `$`                              |
| **Save State**      | `Ctrl+Space` then `Ctrl + s` (Auto-saves every 5m) |
| **Restore State**   | `Ctrl+Space` then `Ctrl + r` (Auto-loads on boot)  |
| **Reload Config**   | `Ctrl+Space` then `r`                              |
| **Install Plugins** | `Ctrl+Space` then `I` (Capital i)                  |

## 📝 Copy / Paste / Log Grabber

| Action                  | MacOS Shortcut (Alacritty)  | Tmux Shortcut                           |
| :---------------------- | :-------------------------- | :-------------------------------------- |
| **Enter Copy Mode**     | `Cmd + F`                   | `Ctrl+Space` then `v`                   |
| **Start Selection**     | _(in copy mode)_ `v`        | _(in copy mode)_ `v`                    |
| **Select Line**         | _(in copy mode)_ `V`        | _(in copy mode)_ `V`                    |
| **Block Select**        | _(in copy mode)_ `Ctrl+V`   | _(in copy mode)_ `Ctrl+V`              |
| **Yank (Copy)**         | _(in copy mode)_ `y`        | _(in copy mode)_ `y`                    |
| **Cancel Selection**    | _(in copy mode)_ `Escape`   | _(in copy mode)_ `Escape`              |
| **Search Forward**      | _(in copy mode)_ `/`        | _(in copy mode)_ `/`                    |
| **Search Backward**     | _(in copy mode)_ `?`        | _(in copy mode)_ `?`                    |
| **Log Grabber (fzf)**   | `Cmd + G`                   | `Ctrl+Space` then `g`                   |
| **Copy (native)**       | `Cmd + C`                   | _(mouse select)_                        |
| **Paste**               | `Cmd + V`                   | `Cmd + V`                               |

### 🔍 Log Grabber Workflow

1. Press `Cmd + G` (or `Prefix + g`) to open the log grabber popup
2. **Preview pane** shows ±5 lines of context around the highlighted line
3. Type to fuzzy-search through your terminal scrollback
4. Press `Tab` to select multiple lines
5. Press `Enter` — selected lines are copied to your clipboard
6. A **preview popup** confirms what you grabbed — press any key to dismiss

| Filter Keybind | Effect                                    |
| :------------- | :---------------------------------------- |
| `Ctrl + E`     | Show only ERROR / WARN / FATAL / PANIC    |
| `Ctrl + D`     | Show only debug / log / trace lines       |
| `Ctrl + A`     | Reset — show all lines                    |

> **Tip**: You can also run `~/.config/tmux/log_grabber.sh debug.log` directly to search a log file.
