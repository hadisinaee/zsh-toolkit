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

function falias-usage() {
  echo "falias - fuzzy alias picker"
  echo
  echo "Usage:"
  echo "  falias         open the alias picker"
  echo "  falias --help  show help"
}

# ---------------------------------------------------------------------------
# falias - fuzzy alias picker
#
# Usage:
#   falias        fzf picker over all aliases
#                 Enter puts expansion in prompt buffer (edit before running)
#                 Ctrl-y copies expansion to clipboard
# ---------------------------------------------------------------------------
function falias() {
  case "${1:-}" in
    help|-h|--help) falias-usage; return 0 ;;
  esac

  local out action sel expansion
  local -a lines=()

  # $aliases is a zsh built-in associative array — no parsing needed
  for name val in ${(kv)aliases}; do
    lines+=("$name  →  $val")
  done

  out=$(printf '%s\n' "${(o)lines[@]}" \
    | fzf --prompt="alias> " \
          --expect=ctrl-y \
          --height=40% --layout=reverse \
          --header='Enter: edit+run | Ctrl-y: copy')

  [[ -z "$out" ]] && return
  local -a result=("${(@f)out}")
  action="${result[1]}" sel="${result[2]}"
  [[ -z "$sel" ]] && return
  expansion="${sel#*  →  }"

  if [[ "$action" == "ctrl-y" ]]; then
    printf '%s' "$expansion" | pbcopy
    echo "copied: $expansion"
  else
    print -z "$expansion"
  fi
}

function fenv-usage() {
  echo "fenv - fuzzy environment picker"
  echo
  echo "Usage:"
  echo "  fenv         open the exported environment picker"
  echo "  fenv --help  show help"
}

# ---------------------------------------------------------------------------
# fenv - fuzzy env var picker
#
# Usage:
#   fenv          fzf picker over exported env vars (sorted)
#                 Enter copies value to clipboard
#                 Ctrl-e re-exports the var in the current shell
# ---------------------------------------------------------------------------
function fenv() {
  case "${1:-}" in
    help|-h|--help) fenv-usage; return 0 ;;
  esac

  local out action line key val
  local -a lines=()

  # $parameters is a zsh built-in — filter to exported vars only
  for name in ${(k)parameters[(R)*export*]}; do
    lines+=("$name=${(P)name}")
  done

  out=$(printf '%s\n' "${(o)lines[@]}" \
    | fzf --prompt="env> " \
          --expect=ctrl-e \
          --height=40% --layout=reverse \
          --preview='echo {} | cut -d= -f2- | tr ":" "\n"' \
          --preview-window='right:40%:wrap' \
          --header='Enter: copy value | Ctrl-e: re-export')

  [[ -z "$out" ]] && return
  local -a result=("${(@f)out}")
  action="${result[1]}" line="${result[2]}"
  [[ -z "$line" ]] && return
  key="${line%%=*}"
  val="${line#*=}"

  if [[ "$action" == "ctrl-e" ]]; then
    export "${key}=${val}"
    echo "exported: $key"
  else
    printf '%s' "$val" | pbcopy
    echo "copied: $key"
  fi
}
