# Bookmarks file lives inside the repo, gitignored alongside local.zsh
typeset -g BM_FILE="$ZSH_CONFIG_ROOT/zsh/bookmarks"
[[ -f "$BM_FILE" ]] || touch "$BM_FILE"

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
  local line
  line=$(grep -v '^[[:space:]]*#' "$BM_FILE" \
    | fzf --prompt="bookmark> " \
          --preview='rg --files "$(cut -d= -f2- <<< {})" 2>/dev/null | head -50')
  [[ -z "$line" ]] && return
  cd "${line#*=}"
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
  sed -i '' "/^${name}=/d" "$BM_FILE"
  unset "$name"
  echo "removed: $name"
}

# list all (column aligns name and path neatly)
function _bm_ls() {
  column -t -s= "$BM_FILE"
}
