# Bookmarks file lives inside the repo, gitignored alongside local.zsh
typeset -g BM_FILE="$ZSH_CONFIG_ROOT/zsh/bookmarks"
[[ -f "$BM_FILE" ]] || touch "$BM_FILE"

function _bm_delete_entry() {
  emulate -L zsh

  local name="$1"

  _zsh_toolkit_kv_update_file "$BM_FILE" "$name" "" delete
}

function bm-usage() {
  case "${1:-}" in
    "")
      echo "bm - bookmarks"
      echo
      echo "Usage:"
      echo "  bm                 open the bookmark picker (Ctrl-Y copies path)"
      echo "  bm add [name] [path]  add or update a bookmark"
      echo "  bm rm              remove a bookmark"
      echo "  bm ls              list bookmarks"
      echo "  bm help [subcommand]  show help"
      ;;
    add) echo "usage: bm add [name] [path]" ;;
    rm)  echo "usage: bm rm" ;;
    ls)  echo "usage: bm ls" ;;
    *)   echo "bm: unknown subcommand: $1"; return 1 ;;
  esac
}

function bm() {
  case "$1" in
    help|-h|--help) bm-usage "${@:2}" ;;
    add) _bm_add "${@:2}" ;;
    rm)  _bm_rm ;;
    ls)  _bm_ls ;;
    *)   _bm_pick ;;
  esac
}

# fzf picker → cd; rg --files for rich directory preview
function _bm_pick() {
  local line bookmark_path
  line=$(grep -v '^[[:space:]]*#' "$BM_FILE" \
    | fzf --prompt="bookmark> " \
          --height=40% --layout=reverse \
          --delimiter='=' \
          --header='Enter: cd | Ctrl-d: delete bookmark | Ctrl-y: copy path' \
          --exit-0 \
          --bind="ctrl-d:execute-silent(zsh -fc 'ZSH_CONFIG_ROOT=\"\$1\"; source \"\$ZSH_CONFIG_ROOT/zsh/bm.zsh\"; _bm_delete_entry \"\$2\"' _ \"$ZSH_CONFIG_ROOT\" \"{1}\")+reload(grep -v '^[[:space:]]*#' \"$BM_FILE\")" \
          --bind="ctrl-y:execute-silent(printf '%s' {2..} | pbcopy)+abort" \
          --preview='rg --files "$(cut -d= -f2- <<< {})" 2>/dev/null | head -50')
  [[ -z "$line" ]] && return
  bookmark_path="${line#*=}"
  cd "${~bookmark_path}"
}

# add bookmark
function _bm_add() {
  local name="${1:-$(basename "$PWD")}"
  local bookmark_path="${2:-$PWD}"

  bookmark_path="${~bookmark_path:A}"
  _zsh_toolkit_kv_update_file "$BM_FILE" "$name" "$bookmark_path" set
  echo "bookmarked: $name → $bookmark_path"
}

# remove via fzf picker
function _bm_rm() {
  local name
  name=$(cut -d= -f1 "$BM_FILE" | fzf --prompt="remove> ")
  [[ -z "$name" ]] && return
  _bm_delete_entry "$name" || return 1
  echo "removed: $name"
}

# list all (column aligns name and path neatly)
function _bm_ls() {
  column -t -s= "$BM_FILE"
}
