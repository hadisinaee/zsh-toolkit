# Bookmarks file lives inside the repo, gitignored alongside local.zsh
typeset -g BM_FILE="$ZSH_CONFIG_ROOT/zsh/bookmarks"
[[ -f "$BM_FILE" ]] || touch "$BM_FILE"

function _bm_delete_entry() {
  emulate -L zsh

  local name="$1"
  local line
  local -a lines

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == *=* && "${line%%=*}" == "$name" ]]; then
      continue
    fi

    lines+=("$line")
  done < "$BM_FILE"

  : > "$BM_FILE" || return 1

  if (( ${#lines[@]} > 0 )); then
    printf '%s\n' "${lines[@]}" > "$BM_FILE" || return 1
  fi
}

# Auto-export all bookmarks as env vars at init
function _bm_export_all() {
  local name path
  while IFS='=' read -r name path; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    export "${name}=${path}"
  done < "$BM_FILE"
}
_bm_export_all

function bm() {
  case "$1" in
    add) _bm_add "${@:2}" ;;
    rm)  _bm_rm ;;
    ls)  _bm_ls ;;
    *)   _bm_pick ;;
  esac
}

# fzf picker → cd; rg --files for rich directory preview
function _bm_pick() {
  local line path
  line=$(grep -v '^[[:space:]]*#' "$BM_FILE" \
    | fzf --prompt="bookmark> " \
          --height=40% --layout=reverse \
          --delimiter='=' \
          --header='Enter: cd | Ctrl-d: delete bookmark' \
          --exit-0 \
          --bind="ctrl-d:execute-silent(zsh -fc 'ZSH_CONFIG_ROOT=\"\$1\"; source \"\$ZSH_CONFIG_ROOT/zsh/bm.zsh\"; _bm_delete_entry \"\$2\"' _ \"$ZSH_CONFIG_ROOT\" \"{1}\")+reload(grep -v '^[[:space:]]*#' \"$BM_FILE\")" \
          --preview='rg --files "$(cut -d= -f2- <<< {})" 2>/dev/null | head -50')
  [[ -z "$line" ]] && return
  path="${line#*=}"
  cd "${~path}"
}

# add bookmark
function _bm_add() {
  local name="${1:-$(basename "$PWD")}"
  local path="${2:-$PWD}"
  path="${path/#\~/$HOME}"
  sed -i '' "/^${name}=/d" "$BM_FILE"
  printf '%s=%s\n' "$name" "$path" >> "$BM_FILE"
  export "${name}=${path}"
  echo "bookmarked: $name → $path"
}

# remove via fzf picker
function _bm_rm() {
  local name
  name=$(cut -d= -f1 "$BM_FILE" | fzf --prompt="remove> ")
  [[ -z "$name" ]] && return
  _bm_delete_entry "$name" || return 1
  unset "$name"
  echo "removed: $name"
}

# list all (column aligns name and path neatly)
function _bm_ls() {
  column -t -s= "$BM_FILE"
}
