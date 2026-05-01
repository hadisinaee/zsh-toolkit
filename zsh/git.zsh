# ============================================================
# GIT
# ============================================================

# Oh My Zsh's git plugin defines aliases for several short git commands.
# Remove only the names this module redefines as functions.
local _zsh_toolkit_git_conflict
for _zsh_toolkit_git_conflict in gco ga gd gl glo; do
  unalias "$_zsh_toolkit_git_conflict" 2>/dev/null
done
unset _zsh_toolkit_git_conflict

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias gb="git branch"
alias grb="git rebase"
alias glg="git log --stat"
alias gcl="git clone"
alias gp="git push"
alias gdw="git diff --word-diff"
alias gst="git stash"
alias gc="git commit -v"
alias gss="git status -s"

function gco-usage() {
  echo "gco - git checkout helper"
  echo
  echo "Usage:"
  echo "  gco           open the branch picker"
  echo "  gco <branch>  check out a branch directly"
}

# ---------------------------------------------------------------------------
# gco - checkout a branch, with fzf picker when no args given
#
# Usage:
#   gco           fzf picker over local branches
#   gco <branch>  direct checkout
# ---------------------------------------------------------------------------
function gco() {
  case "${1:-}" in
    help|-h|--help) gco-usage; return 0 ;;
  esac

  if [[ $# -gt 0 ]]; then
    git checkout "$@"
    return
  fi

  local branch
  branch="$(git branch --sort=-committerdate --format='%(refname:short)' 2>/dev/null |
    fzf --height=40% --reverse --border --prompt='branch > ' \
        --preview 'git log --oneline --decorate --color=always -20 {}')"

  [[ -n "$branch" ]] && git checkout "$branch"
}

function ga-usage() {
  echo "ga - git add helper"
  echo
  echo "Usage:"
  echo "  ga         open the file picker"
  echo "  ga <file>  add one or more paths directly"
}

# ---------------------------------------------------------------------------
# ga - stage files, with fzf multi-select picker when no args given
#
# Usage:
#   ga            fzf multi-select over unstaged/untracked files
#   ga <file>     direct git add
# ---------------------------------------------------------------------------
function ga() {
  case "${1:-}" in
    help|-h|--help) ga-usage; return 0 ;;
  esac

  if [[ $# -gt 0 ]]; then
    git add "$@"
    return
  fi

  local selected files file
  selected="$(git -c color.status=always status --short 2>/dev/null |
    fzf --height=50% --reverse --border --prompt='add > ' \
        --ansi --multi \
        --preview 'git diff --color=always -- {-1}')"

  [[ -z "$selected" ]] && return 0

  files="$(printf '%s\n' "$selected" | cut -c4-)"
  while IFS= read -r file; do
    [[ -n "$file" ]] && git add -- "$file"
  done <<< "$files"
}

# ---------------------------------------------------------------------------
# Helpers for gd preview and file extraction
# ---------------------------------------------------------------------------
function _zsh_toolkit_git_status_path() {
  local line="$1"
  local file_path="${line:3}"

  [[ "$file_path" == *" -> "* ]] && file_path="${file_path##* -> }"
  printf '%s\n' "$file_path"
}

function _zsh_toolkit_git_show_diff() {
  local line="$1"
  local file_path

  file_path="$(_zsh_toolkit_git_status_path "$line")"
  [[ -z "$file_path" ]] && return 1

  if [[ "${line:0:2}" == "??" ]]; then
    git diff --no-index --color=always -- /dev/null "$file_path"
    return
  fi

  if ! git rev-parse --verify --quiet HEAD >/dev/null; then
    git diff --cached --color=always -- "$file_path"
    return
  fi

  git diff HEAD --color=always -- "$file_path"
}

function gd-usage() {
  echo "gd - git diff helper"
  echo
  echo "Usage:"
  echo "  gd         open the changed-file picker"
  echo "  gd <path>  show git diff for one or more paths"
}

# ---------------------------------------------------------------------------
# gd - diff files, with fzf picker when no args given
#
# Usage:
#   gd            fzf picker over tracked + untracked files with diff preview
#   gd <file>     direct git diff
# ---------------------------------------------------------------------------
function gd() {
  case "${1:-}" in
    help|-h|--help) gd-usage; return 0 ;;
  esac

  if [[ $# -gt 0 ]]; then
    git diff "$@"
    return
  fi

  local selected file
  selected="$(git status --short --untracked-files=all 2>/dev/null |
    fzf --height=50% --reverse --border --prompt='diff > ' \
        --preview 'zsh -c '"'"'source "'"$ZSH_CONFIG_ROOT"'/zsh/git.zsh"; _zsh_toolkit_git_show_diff "$1"'"'"' _ {}')"

  [[ -z "$selected" ]] && return 0

  file="$(_zsh_toolkit_git_status_path "$selected")"
  [[ -n "$file" ]] && _zsh_toolkit_git_show_diff "$selected"
}

function gl-usage() {
  echo "gl - git log helper"
  echo
  echo "Usage:"
  echo "  gl         open the commit picker"
  echo "  gl <args>  run git log --oneline --decorate <args>"
}

# ---------------------------------------------------------------------------
# gl - interactive git log picker with rich preview
#
# Usage:
#   gl            fzf picker over commits with detailed preview
#   gl <args>     direct git log --oneline --decorate <args>
# ---------------------------------------------------------------------------
function gl() {
  case "${1:-}" in
    help|-h|--help) gl-usage; return 0 ;;
  esac

  if [[ $# -gt 0 ]]; then
    git log --oneline --decorate "$@"
    return
  fi

  git log --oneline --decorate --color=always 2>/dev/null |
    fzf --height=60% --reverse --border --prompt='log > ' \
        --ansi \
        --preview 'git show --stat --patch --color=always {1}' \
        --preview-window='right:70%:wrap' \
        --bind 'enter:execute(git show --stat --patch --color=always {1} | bat --language=diff --paging=always)'
}

# ---------------------------------------------------------------------------
# glo - backwards-compatible wrapper for gl
# ---------------------------------------------------------------------------
function glo() {
  gl "$@"
}

function gbinfo-usage() {
  echo "gbinfo - branch tracking summary"
  echo
  echo "Usage:"
  echo "  gbinfo [pattern...]  list local branches and upstream state"
}

# ---------------------------------------------------------------------------
# gbinfo - list local git branches and their upstream tracking state
#
# Usage: gbinfo [pattern...]
# ---------------------------------------------------------------------------
function gbinfo() {
  case "${1:-}" in
    help|-h|--help) gbinfo-usage; return 0 ;;
  esac

  local -a patterns
  if (( $# > 0 )); then
    patterns=("$@")
  else
    patterns=('.*')
  fi

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: not in a git repository" >&2
    return 1
  fi

  echo "# SYNC: = up-to-date, > ahead, < behind, <> diverged, gone missing upstream, local no upstream"
  printf '%-3s %-28s %-28s %-8s %-12s %s\n' 'CUR' 'BRANCH' 'UPSTREAM' 'SYNC' 'UPDATED' 'SUBJECT'

  local found=0
  local head branch upstream track updated subject sync pattern matches
  while IFS='|' read -r head branch upstream track updated subject; do
    matches=false
    for pattern in "${patterns[@]}"; do
      if [[ "$branch" =~ "$pattern" ]]; then
        matches=true
        break
      fi
    done
    [[ "$matches" == false ]] && continue

    found=1
    if [[ -z "$upstream" ]]; then
      upstream='-'
      sync='local'
    else
      if git rev-parse --verify --quiet "refs/remotes/$upstream" >/dev/null 2>&1; then
        sync="${track:-=}"
      else
        sync='gone'
      fi
    fi

    printf '%-3s %-28s %-28s %-8s %-12s %s\n' "$head" "$branch" "$upstream" "$sync" "${updated:--}" "$subject"
  done < <(
    git for-each-ref \
      --sort=-committerdate \
      --format='%(if)%(HEAD)%(then)*%(else) %(end)|%(refname:short)|%(upstream:short)|%(upstream:trackshort)|%(committerdate:short)|%(subject)' \
      refs/heads
  )

  if (( ! found )); then
    echo "gbinfo: no branches matched patterns: ${patterns[*]}"
  fi
}

function git-exclude-usage() {
  echo "git-exclude - add repo-local ignore patterns"
  echo
  echo "Usage:"
  echo "  git-exclude <pattern> [pattern...]"
}

# ---------------------------------------------------------------------------
# git-exclude - add a pattern to the repo's local git exclude file
#
# Invocable as: git-exclude <pattern>
#
# Usage:
#   git-exclude <pattern> [pattern...]   e.g. git-exclude .env.local .envrc
# ---------------------------------------------------------------------------
function git-exclude() {
  case "${1:-}" in
    help|-h|--help) git-exclude-usage; return 0 ;;
  esac

  if (( $# == 0 )); then
    git-exclude-usage
    return 1
  fi

  local git_dir
  git_dir="$(git rev-parse --git-dir 2>/dev/null)"
  if [[ -z "$git_dir" ]]; then
    echo "git-exclude: not in a git repository"
    return 1
  fi

  local exclude_file="$git_dir/info/exclude"
  local pattern
  touch "$exclude_file"

  for pattern in "$@"; do
    if grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
      echo "git-exclude: '$pattern' is already in $exclude_file"
      continue
    fi

    echo "$pattern" >> "$exclude_file"
    echo "git-exclude: added '$pattern' to $exclude_file"
  done
}
