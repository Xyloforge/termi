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
