# Customization Guide

## Changing Colors
Alacritty colors are defined in `config/alacritty/catppuccin-mocha.toml`.
- You can Replace this file with another theme TOML.
- Update `config/alacritty/alacritty.toml` to point to the new theme file in the `import` section.

## Adding Tmux Plugins
1. Open `config/tmux/tmux.conf`.
2. Find the plugins section:
   ```tmux
   set -g @plugin 'tmux-plugins/tpm'
   # Add new plugins here
   set -g @plugin 'github_username/plugin_name'
   ```
3. Save the file.
4. Reload Tmux config: `Ctrl + Space` then `r`.
5. Install plugins: `Ctrl + Space` then `I` (Shift + i).

## Changing Fonts
1. Open `config/alacritty/alacritty.toml`.
2. Find the `[font]` section:
   ```toml
   [font]
   size = 20.0
   normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
   ```
3. Change the `family` to your desired font. Ensure the font is installed on your system.
4. Alacritty updates instantly when you save.

## Updating Keybinds
If you want to change `Cmd+D` to something else:
1. Open `config/alacritty/alacritty.toml`.
2. Find the keybinding:
   ```toml
   { key = "D", mods = "Command", chars = "\x00%" }
   ```
3. Change `key` or `mods` as needed.
4. If you change the Tmux action (the `chars`), make sure it matches a valid Tmux prefix sequence.
   - `\x00` is `Ctrl+Space`.
   - The character after is the Tmux key.

## Creating a Local Tmux Config
If you want machine-specific settings without dirtying the main `tmux.conf`:
1. Create `config/tmux/tmux.conf.local`.
2. Add this line to the end of `config/tmux/tmux.conf`:
   ```tmux
   source-file ~/.config/tmux/tmux.conf.local
   ```
