#!/usr/bin/env bash
set -euo pipefail

packages=(
  fzf
  bat
  ripgrep
  tmux
  kubectl
  starship
  mise
  terraform
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
