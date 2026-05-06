# ============================================================
# TOOL INITIALIZATION
# ============================================================

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)

  export FZF_CTRL_R_OPTS="
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --color header:italic
    --header 'Press CTRL-Y to copy command into clipboard'"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

autoload -Uz compinit
compinit

# --- Keybindings ---
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# --- Completion styling ---
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Plugins (installed via scripts/install.sh) ---
# fzf-tab must come after compinit and after fzf --zsh (so it can override Tab)
[[ -f "$ZSH_CONFIG_ROOT/plugins/fzf-tab/fzf-tab.plugin.zsh" ]] && \
  source "$ZSH_CONFIG_ROOT/plugins/fzf-tab/fzf-tab.plugin.zsh"

[[ -f "$ZSH_CONFIG_ROOT/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$ZSH_CONFIG_ROOT/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting must be sourced last
[[ -f "$ZSH_CONFIG_ROOT/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_CONFIG_ROOT/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- Zoxide ---
# cd is replaced by zoxide; z is a shorthand alias
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
  alias z='cd'
fi
