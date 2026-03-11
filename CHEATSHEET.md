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

## 📝 Copy / Paste

| Action        | Shortcut              |
| :------------ | :-------------------- |
| **Copy Mode** | `Ctrl+Space` then `[` |
| **Paste**     | `Cmd + V`             |
