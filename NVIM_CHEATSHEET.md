# Neovim Cheatsheet

> Leader key = `Space`

---

## Modes

| Key | Mode |
|-----|------|
| `i` | Insert (before cursor) |
| `a` | Insert (after cursor) |
| `o` | Insert (new line below) |
| `O` | Insert (new line above) |
| `I` | Insert (start of line) |
| `A` | Insert (end of line) |
| `v` | Visual (character) |
| `V` | Visual (line) |
| `Ctrl+v` | Visual (block/column) |
| `Esc` | Back to Normal + clear search highlight |

---

## Navigation

### Cursor
| Key | Action |
|-----|--------|
| `h j k l` | Left / Down / Up / Right |
| `w` | Next word start |
| `b` | Prev word start |
| `e` | Next word end |
| `0` | Line start |
| `$` | Line end |
| `^` | First non-blank character |
| `gg` | Top of file |
| `G` | Bottom of file |
| `{` / `}` | Prev / Next paragraph |
| `%` | Jump to matching bracket |
| `Ctrl+d` | Scroll half-page down (centered) |
| `Ctrl+u` | Scroll half-page up (centered) |

### Search
| Key | Action |
|-----|--------|
| `/text` | Search forward |
| `?text` | Search backward |
| `n` | Next match (centered) |
| `N` | Prev match (centered) |
| `*` | Search word under cursor |
| `#` | Search word under cursor (backward) |

---

## File Explorer (nvim-tree)

| Key | Action |
|-----|--------|
| `Space ee` | Toggle file tree |
| `Space eo` | Focus file tree (from editor) |
| `Space ef` | Reveal current file in tree |
| `Space ec` | Collapse all folders |

### Inside the tree
| Key | Action |
|-----|--------|
| `Enter` | Open file |
| `Ctrl+v` | Open in vertical split |
| `Ctrl+x` | Open in horizontal split |
| `Ctrl+t` | Open in new tab |
| `a` | Create new file / folder (end name with `/` for folder) |
| `d` | Delete file |
| `r` | Rename file |
| `x` | Cut |
| `c` | Copy |
| `p` | Paste |
| `I` | Toggle hidden files |
| `H` | Toggle dotfiles |
| `R` | Refresh tree |
| `q` | Close tree |

---

## Windows & Splits

| Key | Action |
|-----|--------|
| `Space sv` | Split vertical |
| `Space sh` | Split horizontal |
| `Ctrl+h` | Focus left split |
| `Ctrl+j` | Focus split below |
| `Ctrl+k` | Focus split above |
| `Ctrl+l` | Focus right split |
| `:close` | Close current split |
| `:only` | Close all other splits |

---

## Buffers (Tabs)

| Key | Action |
|-----|--------|
| `Shift+l` | Next buffer |
| `Shift+h` | Previous buffer |
| `Space bd` | Delete (close) current buffer |
| `Space fb` | Fuzzy find open buffers |

---

## File Finding (Telescope)

| Key | Action |
|-----|--------|
| `Space Space` | Find files in project |
| `Space /` | Live grep (search text in project) |
| `Space fr` | Recent files |
| `Space fb` | Open buffers |
| `Space fh` | Help tags |
| `Space fd` | Diagnostics list |
| `Space fc` | Commands |
| `Space fg` | Git changed files |

### Inside Telescope
| Key | Action |
|-----|--------|
| `Ctrl+j/k` | Move up/down |
| `Enter` | Open selected |
| `Ctrl+v` | Open in vertical split |
| `Ctrl+x` | Open in horizontal split |
| `Ctrl+t` | Open in new tab |
| `Esc` | Close |

---

## Editing

### Save & Quit
| Key | Action |
|-----|--------|
| `Space w` | Save |
| `Space q` | Quit |
| `Space Q` | Quit all (force) |

### Copy / Paste / Delete
| Key | Action |
|-----|--------|
| `yy` | Copy line |
| `yw` | Copy word |
| `y$` | Copy to end of line |
| `dd` | Delete line |
| `dw` | Delete word |
| `d$` | Delete to end of line |
| `p` | Paste after |
| `P` | Paste before |
| `Space p` | Paste without overwriting register (visual) |
| `u` | Undo |
| `Ctrl+r` | Redo |

### Change
| Key | Action |
|-----|--------|
| `cc` | Change whole line |
| `cw` | Change word |
| `ci"` | Change inside quotes |
| `ca(` | Change around parentheses |
| `r` | Replace single character |

### Move Lines (Visual Mode)
| Key | Action |
|-----|--------|
| `J` | Move selected lines down |
| `K` | Move selected lines up |

### Commenting (Comment.nvim)
| Key | Action |
|-----|--------|
| `gcc` | Comment/uncomment line |
| `gc` + motion | Comment block (e.g. `gc3j`) |
| `gc` (visual) | Comment selection |

### Surround (nvim-surround)
| Key | Action |
|-----|--------|
| `ys` + motion + char | Add surround (e.g. `ysiw"` → wrap word in quotes) |
| `cs` + old + new | Change surround (e.g. `cs'"` → `'` to `"`) |
| `ds` + char | Delete surround (e.g. `ds"` → remove quotes) |

---

## LSP (Code Intelligence)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find all references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `Space rn` | Rename symbol |
| `Space ca` | Code actions |
| `Space f` | Format file |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `Space e` | Show diagnostic in float |

---

## Diagnostics / Errors (Trouble)

| Key | Action |
|-----|--------|
| `Space xx` | Toggle Trouble panel |
| `Space xd` | Document diagnostics |
| `Space xw` | Workspace diagnostics |
| `Space xq` | Quickfix list |

---

## Git

### Hunks in gutter (gitsigns)
| Key | Action |
|-----|--------|
| `]h` | Next changed hunk |
| `[h` | Prev changed hunk |
| `Space hs` | Stage hunk |
| `Space hr` | Reset hunk |
| `Space hS` | Stage entire buffer |
| `Space hp` | Preview hunk |
| `Space hb` | Blame current line |
| `Space hd` | Diff this file |

### Git TUI
| Key | Action |
|-----|--------|
| `Space gg` | Open Fugitive (git status) |
| `Space gp` | Git push |
| `Space gl` | Git pull |
| `Space gn` | Open Neogit (Magit-style) |

---

## Plugin Manager (Lazy)

| Command | Action |
|---------|--------|
| `:Lazy` | Open plugin manager |
| `:Lazy sync` | Update all plugins |
| `:Lazy clean` | Remove unused plugins |

## LSP Manager (Mason)

| Command | Action |
|---------|--------|
| `:Mason` | Open LSP/tool installer UI |
| `:checkhealth` | Diagnose any issues |
| `:TSUpdate` | Install/update treesitter parsers |

---

## Typical Workflows

### Open project and start coding
```
nvim .               # open current folder
Space ee             # open file tree
Space Space          # fuzzy find a file
i                    # start typing
Esc → Space w        # save
```

### Create a new file
```
Space ee             # open tree
navigate to folder
a                    # type filename + Enter
```

### Search and replace across project
```
Space /              # live grep to find
:%s/old/new/g        # replace in current file
```

### Fix an error
```
Space xx             # open Trouble panel
Enter                # jump to error
Space ca             # code action to fix
Space f              # format after fix
```
