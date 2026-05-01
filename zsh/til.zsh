# ============================================================
# TIL AND TODO FILE MANAGERS
# ============================================================

alias til="_til"
alias tilv="_tilv"
alias todo="_todo"
alias todov="_todov"

function _notes_topic_file() {
  local dir="$1"
  local topic="$2"

  topic="${topic#"${topic%%[![:space:]]*}"}"
  topic="${topic%"${topic##*[![:space:]]}"}"

  [[ -z "$topic" ]] && return 1
  [[ "$topic" == *.md ]] || topic="${topic}.md"

  printf '%s/%s\n' "$dir" "$topic"
}

function _notes_delete_markdown() {
  local file="$1"

  [[ -n "$file" ]] || return 1
  rm -f -- "$file"
}

function til-usage() {
  case "${1:-}" in
    "")
      echo "til - TIL notes"
      echo
      echo "Usage:"
      echo "  til [topic]   open or create a note in ~/.til/"
      ;;
    *) echo "usage: til [topic]" ;;
  esac
}

function tilv-usage() {
  case "${1:-}" in
    "")
      echo "tilv - TIL note viewer"
      echo
      echo "Usage:"
      echo "  tilv [topic]  view a note in ~/.til/"
      ;;
    *) echo "usage: tilv [topic]" ;;
  esac
}

function todo-usage() {
  case "${1:-}" in
    "")
      echo "todo - TODO notes"
      echo
      echo "Usage:"
      echo "  todo [topic]  open or create a note in ~/.todo/"
      ;;
    *) echo "usage: todo [topic]" ;;
  esac
}

function todov-usage() {
  case "${1:-}" in
    "")
      echo "todov - TODO note viewer"
      echo
      echo "Usage:"
      echo "  todov [topic]  view a note in ~/.todo/"
      ;;
    *) echo "usage: todov [topic]" ;;
  esac
}

function tils-usage() {
  case "${1:-}" in
    "")
      echo "tils - search TIL notes"
      echo
      echo "Usage:"
      echo "  tils <query>  search ~/.til/*.md"
      ;;
    *) echo "usage: tils <query>" ;;
  esac
}

function todos-usage() {
  case "${1:-}" in
    "")
      echo "todos - search TODO notes"
      echo
      echo "Usage:"
      echo "  todos <query>  search ~/.todo/*.md"
      ;;
    *) echo "usage: todos <query>" ;;
  esac
}

function _notes_pick_markdown() {
  local dir="$1"
  local prompt="$2"
  local allow_create="${3:-false}"
  local -a files
  local output query key selection
  local -a lines

  if [[ "$allow_create" == "true" ]]; then
    while true; do
      files=("$dir"/*.md(N))
      output="$(
        { (( ${#files[@]} > 0 )) && printf '%s\n' "${files[@]}"; } |
          fzf --height=40% --reverse --border --prompt="$prompt" \
              --preview 'bat --color=always {}' \
              --print-query \
              --expect=enter,ctrl-n,ctrl-d \
              --header='enter: open  ctrl-n: create from query  ctrl-d: delete'
      )"

      [[ -z "$output" ]] && return 0

      lines=("${(@f)output}")
      query="${lines[1]}"
      key="${lines[2]}"
      selection="${lines[3]}"

      if [[ "$key" == "ctrl-n" ]]; then
        _notes_topic_file "$dir" "$query"
        return
      fi

      if [[ "$key" == "ctrl-d" ]]; then
        [[ -n "$selection" ]] || continue
        _notes_delete_markdown "$selection"
        continue
      fi

      [[ -n "$selection" ]] && printf '%s\n' "$selection"
      return 0
    done
  fi

  while true; do
    files=("$dir"/*.md(N))
    (( ${#files[@]} == 0 )) && return 0

    output="$(
      printf '%s\n' "${files[@]}" |
        fzf --height=40% --reverse --border --prompt="$prompt" \
            --preview 'bat --color=always {}' \
            --expect=enter,ctrl-d \
            --header='enter: open  ctrl-d: delete'
    )"

    [[ -z "$output" ]] && return 0

    lines=("${(@f)output}")
    key="${lines[1]}"
    selection="${lines[2]}"

    if [[ "$key" == "ctrl-d" ]]; then
      [[ -n "$selection" ]] || continue
      _notes_delete_markdown "$selection"
      continue
    fi

    [[ -n "$selection" ]] && printf '%s\n' "$selection"
    return 0
  done
}

function _notes_open_or_pick() {
  local dir="$1"
  local prompt="$2"
  local viewer="$3"
  local topic="$4"
  local allow_create="${5:-false}"
  local file=""

  mkdir -p "$dir"

  if [[ -n "$topic" ]]; then
    file="$(_notes_topic_file "$dir" "$topic")" || return 1
  else
    file="$(_notes_pick_markdown "$dir" "$prompt" "$allow_create")"
    [[ -z "$file" ]] && return 0
  fi

  "$viewer" "$file"
}

function _notes_search() {
  local dir="$1"
  local prompt="$2"
  local query="$3"
  local -a files
  local result file line

  files=("$dir"/*.md(N))
  (( ${#files[@]} == 0 )) && return 0

  result="$(rg --line-number --color=always --smart-case -- "$query" "${files[@]}" 2>/dev/null |
    fzf --ansi --height=50% --reverse --border --prompt="$prompt" \
        --delimiter=':' \
        --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window='right:50%:wrap:+{2}-5')"

  [[ -z "$result" ]] && return 0

  file="$(echo "$result" | cut -d':' -f1)"
  line="$(echo "$result" | cut -d':' -f2)"
  _zsh_toolkit_open_in_editor +"$line" "$file"
}

# ---------------------------------------------------------------------------
# _til - open a TIL file in your configured editor
#
# Usage:
#   til           fzf picker over ~/.til/*.md
#   til <topic>   open (or create) ~/.til/<topic>.md directly
# ---------------------------------------------------------------------------
function _til() {
  case "${1:-}" in
    help|-h|--help) til-usage; return 0 ;;
  esac
  _notes_open_or_pick "$HOME/.til" "til > " "_zsh_toolkit_open_in_editor" "$1" true
}

# ---------------------------------------------------------------------------
# _tilv - view a TIL file with bat
#
# Usage:
#   tilv           fzf picker over ~/.til/*.md
#   tilv <topic>   view ~/.til/<topic>.md directly
# ---------------------------------------------------------------------------
function _tilv() {
  case "${1:-}" in
    help|-h|--help) tilv-usage; return 0 ;;
  esac
  _notes_open_or_pick "$HOME/.til" "til > " "bat" "$1"
}

# ---------------------------------------------------------------------------
# _todo - open a todo file in your configured editor
#
# Usage:
#   todo           fzf picker over ~/.todo/*.md
#   todo <topic>   open (or create) ~/.todo/<topic>.md directly
# ---------------------------------------------------------------------------
function _todo() {
  case "${1:-}" in
    help|-h|--help) todo-usage; return 0 ;;
  esac
  _notes_open_or_pick "$HOME/.todo" "todo > " "_zsh_toolkit_open_in_editor" "$1" true
}

# ---------------------------------------------------------------------------
# _todov - view a todo file with bat
#
# Usage:
#   todov          fzf picker over ~/.todo/*.md
#   todov <topic>  view ~/.todo/<topic>.md directly
# ---------------------------------------------------------------------------
function _todov() {
  case "${1:-}" in
    help|-h|--help) todov-usage; return 0 ;;
  esac
  _notes_open_or_pick "$HOME/.todo" "todo > " "bat" "$1"
}

# ---------------------------------------------------------------------------
# tils - search inside TIL files with rg + fzf
#
# Usage:
#   tils            falls back to til picker (no query)
#   tils <query>    search across all ~/.til/*.md, Enter opens your editor at line
# ---------------------------------------------------------------------------
function tils() {
  case "${1:-}" in
    help|-h|--help) tils-usage; return 0 ;;
  esac
  if [[ -z "$1" ]]; then
    _til
    return
  fi

  _notes_search "$HOME/.til" "tils > " "$1"
}

# ---------------------------------------------------------------------------
# todos - search inside TODO files with rg + fzf
#
# Usage:
#   todos           falls back to todo picker (no query)
#   todos <query>   search across all ~/.todo/*.md, Enter opens your editor at line
# ---------------------------------------------------------------------------
function todos() {
  case "${1:-}" in
    help|-h|--help) todos-usage; return 0 ;;
  esac
  if [[ -z "$1" ]]; then
    _todo
    return
  fi

  _notes_search "$HOME/.todo" "todos > " "$1"
}
