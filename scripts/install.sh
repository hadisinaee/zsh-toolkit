#!/usr/bin/env bash
set -euo pipefail

ZSH_TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

packages=(
  fzf
  bat
  ripgrep
  tmux
  kubectl
  starship
  mise
  terraform
  zoxide
)

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'scripts/install.sh currently supports macOS with Homebrew only.\n' >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required: https://brew.sh/\n' >&2
  exit 1
fi

printf 'Installing required tools with Homebrew:\n'
printf '  brew install %s\n\n' "${packages[*]}"
brew install "${packages[@]}"

printf '\nInstalled packages:\n'
printf '  - %s\n' "${packages[@]}"

# --- Plugins ---
_plugin_install() {
  local name="$1" url="$2"
  local dest="$ZSH_TOOLKIT_DIR/plugins/$name"
  if [[ -d "$dest" ]]; then
    printf '  updating %s\n' "$name"
    git -C "$dest" pull --ff-only
  else
    printf '  cloning %s\n' "$name"
    git clone --depth=1 "$url" "$dest"
  fi
}

printf '\nInstalling zsh plugins:\n'
_plugin_install fzf-tab             https://github.com/Aloxaf/fzf-tab
_plugin_install zsh-autosuggestions  https://github.com/zsh-users/zsh-autosuggestions
_plugin_install zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

printf '\nDone.\n'
