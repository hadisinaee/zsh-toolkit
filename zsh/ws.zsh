# ============================================================
# WORKSPACE MANAGER (ws)
# ============================================================

# ---------------------------------------------------------------------------
# Private helpers (prefixed _ to signal internal use)
# ---------------------------------------------------------------------------

function _ws_attach() {
  local target="$1"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$target"
  else
    tmux attach-session -t "$target"
  fi
}

function _ws_sanitize_name() {
  local name="${1:l}"
  name="${name//[^a-z0-9_-]/-}"
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  name="${name##(-##)}"
  name="${name%%(-##)}"
  printf '%s' "$name"
}

function _ws_pick_session() {
  tmux list-sessions -F '#S' 2>/dev/null |
    fzf --height=50% --reverse --border \
        --prompt='session > ' \
        --preview 'zsh -c "source ~/.zshrc && ws-preview {}"' \
        --preview-window='right:50%:wrap'
}

function _ws_require_session() {
  local session="${1:-$(_ws_pick_session)}"
  [[ -z "$session" ]] && return 0
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "ws: session not found: $session" >&2
    return 1
  fi
  printf '%s' "$session"
}

# ---------------------------------------------------------------------------
# Command registry - single source of truth for help and completion
# ---------------------------------------------------------------------------
typeset -gA _WS_CMDS
_WS_CMDS=(
  ls      "list and interactively switch sessions"
  kill    "kill a named session"
  last    "switch to the previously active session"
  info    "print session details to stdout"
  rename  "rename an existing session"
  cd      "print working directory of session's active pane"
  help    "show this help message"
)

# ---------------------------------------------------------------------------
# ws - workspace manager dispatcher
#
# Usage:
#   ws                             list and switch sessions (default)
#   ws ls                          list and switch sessions
#   ws kill <session>              kill a named session
#   ws last                        switch to the previously active session
#   ws info <session>              print session details to stdout
#   ws rename <old> <new>          rename an existing session
#   ws cd <session>                print working directory of session's first pane
#   ws help [subcommand]           show help
#   ws [-n name] [-p path] [name] [path]
#                                  create or attach to a named tmux session
# ---------------------------------------------------------------------------
function ws() {
  local cmd="${1:-ls}"

  case "$cmd" in
    ls)     ws-ls "${@:2}" ;;
    kill)   ws-kill "${@:2}" ;;
    last)   ws-last ;;
    info)   ws-info "${@:2}" ;;
    rename) ws-rename "${@:2}" ;;
    cd)     ws-cd "${@:2}" ;;
    help)   ws-help "${@:2}" ;;
    -n|-p|[^-]*)
      ws-new "$@"
      ;;
    *)
      echo "ws: unknown subcommand: $cmd"
      echo "Run 'ws help' for usage."
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# ws-ls - interactively list and switch tmux sessions using fzf
#
# Session names show [A] for currently attached sessions.
# When called from inside tmux, opens in a floating popup (no preview).
# WS_POPUP guards against recursion.
#
# Keybindings:
#   Enter    attach/switch to selected session
#   Ctrl-d   kill selected session and refresh list
#   Ctrl-r   rename selected session (prompts inline via tmux)
#   Ctrl-n   create a new session (prompts for name)
#   Esc      close without switching
# ---------------------------------------------------------------------------
function ws-ls() {
  if [[ -n "$TMUX" && -z "$WS_POPUP" ]]; then
    WS_POPUP=1 tmux display-popup -w 80% -h 80% -E "WS_POPUP=1 zsh -c 'source ~/.zshrc && ws-ls'"
    unset WS_POPUP
    return
  fi

  local sessions session
  local _ws_tmp="/tmp/ws_new_session_$$"

  sessions="$(tmux list-sessions -F '#{session_name}#{?session_attached, [A],}' 2>/dev/null || true)"
  [[ -z "$sessions" ]] && return 0

  local preview_opts
  if [[ -n "$WS_POPUP" ]]; then
    preview_opts=(--preview-window=hidden)
  else
    preview_opts=(--preview 'zsh -c "source ~/.zshrc && ws-preview {1}"' --preview-window='right:50%:wrap')
  fi

  session="$(
    printf '%s\n' "$sessions" |
      fzf \
        --prompt='workspace > ' \
        --height=40% \
        --reverse \
        --border \
        --header='Enter: attach | Ctrl-d: delete | Ctrl-r: rename | Ctrl-n: new | Esc: close' \
        "${preview_opts[@]}" \
        --bind 'ctrl-d:execute-silent(tmux kill-session -t {1} 2>/dev/null)+reload(tmux list-sessions -F "#{session_name}#{?session_attached, [A],}" 2>/dev/null || echo "(no sessions)")' \
        --bind 'ctrl-r:execute(printf "Rename \"{1}\" to: " >/dev/tty; IFS= read -r n </dev/tty && [[ -n "$n" ]] && tmux rename-session -t {1} "$n")+reload(tmux list-sessions -F "#{session_name}#{?session_attached, [A],}" 2>/dev/null || echo "(no sessions)")' \
        --bind 'ctrl-n:execute(printf "New session name: " >/dev/tty; IFS= read -r n </dev/tty && [[ -n "$n" ]] && tmux new-session -d -s "$n" -c "$PWD" 2>/dev/null && printf "%s" "$n" > '"$_ws_tmp"')+abort'
  )"

  if [[ -z "$session" || "$session" == "(no sessions)" ]]; then
    local _ws_new
    _ws_new="$(cat "$_ws_tmp" 2>/dev/null)"
    rm -f "$_ws_tmp"
    [[ -n "$_ws_new" ]] && _ws_attach "$_ws_new"
    return 0
  fi

  rm -f "$_ws_tmp"
  _ws_attach "${session%% *}"
}

# ---------------------------------------------------------------------------
# ws-kill - kill a named tmux session
#
# Usage: ws kill <session-name>
# ---------------------------------------------------------------------------
function ws-kill() {
  local session
  session="$(_ws_require_session "$1")" || return 1
  [[ -z "$session" ]] && return 0

  tmux kill-session -t "$session"
  echo "ws: killed session '$session'"
}

# ---------------------------------------------------------------------------
# ws-last - switch to the previously active tmux session (like cd -)
#
# Usage: ws last
# ---------------------------------------------------------------------------
function ws-last() {
  if [[ -z "$TMUX" ]]; then
    local last
    last="$(tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null |
      sort -rn | awk 'NR==1{print $2}')"
    if [[ -z "$last" ]]; then
      echo "ws: no tmux sessions found"
      return 1
    fi
    tmux attach-session -t "$last"
    return
  fi

  tmux switch-client -l
}

# ---------------------------------------------------------------------------
# ws-info - print session details to stdout (non-interactive ws-preview)
#
# Usage: ws info <session-name>
# ---------------------------------------------------------------------------
function ws-info() {
  local session
  session="$(_ws_require_session "$1")" || return 1
  [[ -z "$session" ]] && return 0

  ws-preview "$session"
}

# ---------------------------------------------------------------------------
# ws-help - display usage information
#
# Usage: ws help [subcommand]
# ---------------------------------------------------------------------------
function ws-help() {
  if [[ $# -eq 0 ]]; then
    echo "ws - workspace manager"
    echo
    echo "Usage: ws <subcommand> [args]"
    echo
    echo "Subcommands:"
    local cmd
    for cmd in ls kill last info rename cd help; do
      printf "  %-10s %s\n" "$cmd" "${_WS_CMDS[$cmd]}"
    done
    echo
    echo "  ws <name> [path]   create or attach to a named session"
    return 0
  fi

  case "$1" in
    ls)     echo "usage: ws ls" ;;
    kill)   echo "usage: ws kill <session>" ;;
    last)   echo "usage: ws last" ;;
    info)   echo "usage: ws info <session>" ;;
    rename) echo "usage: ws rename <old-name> <new-name>" ;;
    cd)     echo "usage: ws cd <session>" ;;
    help)   echo "usage: ws help [subcommand]" ;;
    *)      echo "ws: unknown subcommand: $1"; return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# ws-preview - render a summary of a tmux session for the fzf preview pane
#
# Displays session metadata (attached clients, window count), a window list
# with the active window marked, the currently running command in each pane,
# and the current git branch for the active pane's path.
#
# Usage: ws-preview <session-name>
# ---------------------------------------------------------------------------
function ws-preview() {
  local session="$1"
  [[ -z "$session" ]] && return 0

  local info
  info="$(tmux list-sessions -F '#{session_name} #{session_attached} #{session_windows}' 2>/dev/null |
    awk -v s="$session" '$1 == s { print $2, $3 }')"

  local attached="${info%% *}"
  local windows_count="${info##* }"

  echo "Session: $session"
  echo "Attached clients: ${attached:-0}"
  echo "Window count: ${windows_count:-0}"
  echo

  echo "Windows:"
  tmux list-windows -t "$session" -F '  #I:#W#{?window_active, * ,}' 2>/dev/null

  echo
  echo "Active panes:"
  tmux list-panes -t "$session" -F '  #{pane_current_command} (#{pane_current_path})' 2>/dev/null

  echo
  local path branch
  path="$(tmux list-panes -t "$session" -F '#{pane_current_path}' 2>/dev/null | /usr/bin/head -1)"
  branch="$(git -C "$path" branch --show-current 2>/dev/null)"
  echo "Branch: ${branch:-(no git repo)}"
}

# ---------------------------------------------------------------------------
# ws-new - create a new tmux session (or attach if it already exists)
#
# Accepts flags or bare positional arguments for convenience:
#   ws-new [-n name] [-p path] [name] [path]
#
# Name is derived from the directory basename when omitted, lowercased, and
# sanitized so only [a-z0-9_-] characters remain (tmux-safe). Prints a
# message indicating whether a new session was created or an existing one
# was reattached.
# ---------------------------------------------------------------------------
function ws-new() {
  local name=""
  local workspace_path=""
  local OPTIND opt

  while getopts "n:p:" opt; do
    case "$opt" in
      n) name="$OPTARG" ;;
      p) workspace_path="$OPTARG" ;;
      *)
        echo "usage: ws [-n name] [-p path] [name] [path]"
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  [[ -z "$name" && -n "$1" ]] && name="$1" && shift
  [[ -z "$workspace_path" && -n "$1" ]] && workspace_path="$1"

  if [[ -z "$workspace_path" ]]; then
    workspace_path="$PWD"
  fi

  workspace_path="${~workspace_path}"

  if [[ ! -d "$workspace_path" ]]; then
    echo "ws: path does not exist or is not a directory: $workspace_path"
    return 1
  fi

  if [[ -z "$name" ]]; then
    name="$(basename "$workspace_path")"
  fi

  name="$(_ws_sanitize_name "$name")"

  if [[ -z "$name" ]]; then
    echo "ws: session name is empty after sanitization (only special characters were given)"
    return 1
  fi

  if tmux has-session -t "$name" 2>/dev/null; then
    echo "ws: attached to existing session '$name'"
    _ws_attach "$name"
    return
  fi

  tmux new-session -d -s "$name" -c "$workspace_path"
  echo "ws: created new session '$name' at $workspace_path"
  _ws_attach "$name"
}

# ---------------------------------------------------------------------------
# ws-rename - rename an existing tmux session in-place
#
# Preserves all windows, panes, and running processes.
#
# Usage: ws rename <old-name> <new-name>
# ---------------------------------------------------------------------------
function ws-rename() {
  if [[ $# -lt 2 ]]; then
    echo "usage: ws rename <old-name> <new-name>"
    return 1
  fi

  local old_name="$1"
  local new_name
  new_name="$(_ws_sanitize_name "$2")"

  if [[ -z "$new_name" ]]; then
    echo "ws: new session name is empty after sanitization"
    return 1
  fi

  if ! tmux has-session -t "$old_name" 2>/dev/null; then
    echo "ws: session not found: $old_name"
    return 1
  fi

  tmux rename-session -t "$old_name" "$new_name"
  echo "ws: renamed '$old_name' -> '$new_name'"
}

# ---------------------------------------------------------------------------
# ws-cd - print the working directory of the first pane in a session
#
# Intended for use with command substitution:
#   cd "$(ws cd myapp)"
#
# Usage: ws cd <session-name>
# ---------------------------------------------------------------------------
function ws-cd() {
  local session
  session="$(_ws_require_session "$1")" || return 1
  [[ -z "$session" ]] && return 0

  tmux list-panes -t "$session" -F '#{pane_current_path}' 2>/dev/null | /usr/bin/head -1
}
