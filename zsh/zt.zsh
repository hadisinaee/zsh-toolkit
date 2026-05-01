# ============================================================
# ZSH TOOLKIT HELP SURFACE (zt)
# ============================================================

typeset -ga _ZT_HELP_MODULES=(
  ws
  bm
  sec
  til
  shell
  git
  search
  k8s
)

typeset -gA _ZT_HELP_MODULE_LABELS
_ZT_HELP_MODULE_LABELS=(
  ws     "Workspace"
  bm     "Bookmarks"
  sec    "Secrets"
  til    "Notes"
  shell  "Shell"
  git    "Git"
  search "Search"
  k8s    "Kubernetes"
)

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
  falias
  fenv
  gco
  ga
  gd
  gl
  gbinfo
  git-exclude
  rgg
  ff
  kctx
)

typeset -gA _ZT_HELP_MODULE
_ZT_HELP_MODULE=(
  ws            ws
  bm            bm
  sec           sec
  til           til
  tilv          til
  todo          til
  todov         til
  tils          til
  todos         til
  falias        shell
  fenv          shell
  gco           git
  ga            git
  gd            git
  gl            git
  gbinfo        git
  git-exclude   git
  rgg           search
  ff            search
  kctx          k8s
)

typeset -gA _ZT_HELP_DESCRIPTIONS
_ZT_HELP_DESCRIPTIONS=(
  ws            "workspace manager"
  bm            "bookmarks"
  sec           "secrets"
  til           "open or create a TIL note"
  tilv          "view a TIL note"
  todo          "open or create a TODO note"
  todov         "view a TODO note"
  tils          "search TIL notes"
  todos         "search TODO notes"
  falias        "browse aliases with fzf"
  fenv          "browse exported env vars with fzf"
  gco           "check out a branch"
  ga            "stage files"
  gd            "inspect diffs"
  gl            "browse git history"
  gbinfo        "show branch tracking state"
  git-exclude   "add repo-local ignore patterns"
  rgg           "search files with ripgrep + fzf"
  ff            "find files with ripgrep + fzf"
  kctx          "switch kubectl contexts"
)

typeset -gA _ZT_HELP_USAGE
_ZT_HELP_USAGE=(
  ws            "ws-usage"
  bm            "bm-usage"
  sec           "sec-usage"
  til           "til-usage"
  tilv          "tilv-usage"
  todo          "todo-usage"
  todov         "todov-usage"
  tils          "tils-usage"
  todos         "todos-usage"
  falias        "falias-usage"
  fenv          "fenv-usage"
  gco           "gco-usage"
  ga            "ga-usage"
  gd            "gd-usage"
  gl            "gl-usage"
  gbinfo        "gbinfo-usage"
  git-exclude   "git-exclude-usage"
  rgg           "rgg-usage"
  ff            "ff-usage"
  kctx          "kctx-usage"
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
    local module cmd usage
    local -i printed=0

    echo "zt - zsh toolkit"
    echo
    echo "Usage: zt help [command]"
    echo
    for module in "${_ZT_HELP_MODULES[@]}"; do
      printed=0

      for cmd in "${_ZT_HELP_COMMANDS[@]}"; do
        [[ "${_ZT_HELP_MODULE[$cmd]}" == "$module" ]] || continue

        usage="${_ZT_HELP_USAGE[$cmd]}"
        whence -w "$usage" >/dev/null 2>&1 || continue

        if (( ! printed )); then
          echo "${_ZT_HELP_MODULE_LABELS[$module]}:"
          printed=1
        fi

        printf "  %-12s %s\n" "$cmd" "${_ZT_HELP_DESCRIPTIONS[$cmd]}"
      done

      (( printed )) && echo
    done
    echo "Run 'zt help <command>' for command-specific usage."
    return 0
  fi

  local command="${(j: :)@}"
  local usage_func="${_ZT_HELP_USAGE[$command]}"
  if [[ -z "$usage_func" ]]; then
    echo "zt: unknown command: $command"
    return 1
  fi

  if ! whence -w "$usage_func" >/dev/null 2>&1; then
    echo "zt: help unavailable for: $command"
    return 1
  fi

  "$usage_func"
}
