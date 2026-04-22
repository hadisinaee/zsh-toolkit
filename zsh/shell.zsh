# ============================================================
# SHELL - environment, paths, general aliases
# ============================================================

# --- Environment ---
export GPG_TTY="$(tty)"
export HISTIGNORE="pwd:ls:cd:ll"
export DISABLE_AUTO_TITLE="true"

# --- Paths ---
export PATH="$HOME/.local/bin:$PATH"

# --- General aliases ---
alias resource="source ~/.zshrc"
alias tf="terraform"
