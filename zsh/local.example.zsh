# Copy this file to zsh/local.zsh and customize it.
# If your private config grows, you can also split it into zsh/local.d/*.zsh.
# Files in zsh/local.d/ load before zsh/local.zsh, so local.zsh stays your
# final override file.

# Personal PATH additions.
# export PATH="$HOME/.cargo/bin:$PATH"

# Personal aliases.
# alias gs='git status'

# Advanced module selection.
# Set these before sourcing init.zsh from your own ~/.zshrc if you want them
# to affect which shared modules load.
# typeset -ga ZSH_CONFIG_DISABLED_MODULES=(k8s ws)
# typeset -ga ZSH_CONFIG_MODULES=(shell tools git search)

# Machine-specific or work-only settings belong here.
# export WORKON_HOME="$HOME/venvs"
# alias workon='source "$WORKON_HOME/project/bin/activate"'

# Project path bookmarks — use the bm module instead of manual exports.
# Run these once to populate zsh/bookmarks, then remove the export lines:
# bm add avlbe ~/Projects/arrival/arrival-backend
# bm add cm_home ~/Projects/consolidated_repo/configmgmt
