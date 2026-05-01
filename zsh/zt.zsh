# ============================================================
# ZSH TOOLKIT HELP SURFACE (zt)
# ============================================================

typeset -ga _ZT_HELP_COMMANDS=(
  ws
  bm
  sec
  til
  tilv
  todo
  todov
  tils
  todos
)

typeset -gA _ZT_HELP_DESCRIPTIONS
_ZT_HELP_DESCRIPTIONS=(
  ws    "workspace manager"
  bm    "bookmarks"
  sec   "secrets"
  til   "open or create a TIL note"
  tilv  "view a TIL note"
  todo  "open or create a TODO note"
  todov "view a TODO note"
  tils  "search TIL notes"
  todos "search TODO notes"
)

typeset -gA _ZT_HELP_USAGE
_ZT_HELP_USAGE=(
  ws    "ws-usage"
  bm    "bm-usage"
  sec   "sec-usage"
  til   "til-usage"
  tilv  "tilv-usage"
  todo  "todo-usage"
  todov "todov-usage"
  tils  "tils-usage"
  todos "todos-usage"
)

function zt() {
  local cmd="${1:-help}"

  case "$cmd" in
    help|h|-h|--help)
      zt-help "${@:2}"
      ;;
    *)
      echo "zt: unknown subcommand: $cmd"
      echo "Run 'zt help' for usage."
      return 1
      ;;
  esac
}

function zt-help() {
  emulate -L zsh

  if [[ $# -eq 0 ]]; then
    local cmd usage

    echo "zt - zsh toolkit"
    echo
    echo "Usage: zt help [command]"
    echo
    echo "Commands:"
    for cmd in "${_ZT_HELP_COMMANDS[@]}"; do
      usage="${_ZT_HELP_USAGE[$cmd]}"
      whence -w "$usage" >/dev/null 2>&1 || continue
      printf "  %-8s %s\n" "$cmd" "${_ZT_HELP_DESCRIPTIONS[$cmd]}"
    done
    echo
    echo "Run 'zt help <command>' for command-specific usage."
    return 0
  fi

  local usage_func="${_ZT_HELP_USAGE[$1]}"
  if [[ -z "$usage_func" ]]; then
    echo "zt: unknown command: $1"
    return 1
  fi

  if ! whence -w "$usage_func" >/dev/null 2>&1; then
    echo "zt: help unavailable for: $1"
    return 1
  fi

  "$usage_func"
}
