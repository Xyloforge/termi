# -----------------------------------------------------------------------------
# Zsh Features & Keybindings (Added by Termi Install Script)
# -----------------------------------------------------------------------------

# 1. Syntax Highlighting & Autosuggestions
#    These plugins must be cloned by install.sh to ~/.zsh/plugins/
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# 1.5. Enable Vi Mode (Vim-style navigation)
#      User preference: set -o vi (Standard POSIX style)
set -o vi
export KEYTIMEOUT=1

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q' # block
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} == '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q' # beam
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # beam on startup

# 2. History Search (Ctrl+R) & File Search (Ctrl+T)
#    - Uses fzf if available for super-fast, fuzzy history search
#    - Fallbacks to standard zsh history search if fzf is missing
if command -v fzf &> /dev/null; then
  # Try new fzf setup (0.48+)
  if fzf --zsh &> /dev/null; then
      source <(fzf --zsh)
  else
      # Fallback for older fzf
      # Check common install locations
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
      [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
  fi
  
  # Ensure standard bindings if not set by above
  bindkey '^R' fzf-history-widget
  bindkey '^T' fzf-file-widget
  bindkey '\ec' fzf-cd-widget

else
  # Standard Zsh Search if FZF is missing
  bindkey '^R' history-incremental-search-backward
fi

# 3. Standard Navigation Shortcuts
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^U' kill-whole-line

# 4. Advanced Editing: Edit Command Line in Editor
#    Press 'ESC' then 'v' to open the current command in $EDITOR (e.g., vim/nano)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# 5. Process Monitoring (Activity Monitor Replacement)
if command -v btop &> /dev/null; then
    alias monitor='btop'
    alias process='btop'
    alias top='btop'   # Upgrade top to btop
elif command -v htop &> /dev/null; then
    alias monitor='htop'
    alias process='htop'
    alias top='htop'
else
    alias monitor='top'
fi
# 6. Clipboard Integration (ccat: cat + copy)
alias ccat='_ccat_func'
_ccat_func() {
  if command -v pbcopy &> /dev/null; then
    cat "$@" | pbcopy
  elif command -v xclip &> /dev/null; then
    cat "$@" | xclip -selection clipboard
  elif command -v wl-copy &> /dev/null; then
    cat "$@" | wl-copy
  else
    echo "❌ No clipboard manager found (pbcopy, xclip, wl-copy)"
    return 1
  fi
  echo '✅ Copied to clipboard!'
}

# 6.5. OS Agnostic Open Command
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v xdg-open &> /dev/null; then
  alias open='xdg-open'
fi

# 7. Zoxide (Smarter cd)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# 8. Database Management TUI 
if command -v lazysql &> /dev/null; then
    alias lsql='lazysql'
    alias dbs='lazysql'
fi

if command -v vi-mongo &> /dev/null; then
    alias vmongo='vi-mongo'
    alias mgo='vi-mongo'
fi

if command -v ratisui &> /dev/null; then
    alias rtui='ratisui'
fi

# 8.5 Docker Management TUI
if command -v oxker &> /dev/null; then
    alias ox='oxker'
    alias docker-tui='oxker'
fi

# 9. Port / Process Search
alias pfzf='lsof -i | fzf'

# 10. Kill Process by Port
killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi
    local pids=($(lsof -ti :$1))
    if [ ${#pids[@]} -eq 0 ]; then
        echo "No process running on port $1"
    else
        echo "Killing processes [${pids[@]}] running on port $1..."
        kill -9 "${pids[@]}"
        echo "Done!"
    fi
}
