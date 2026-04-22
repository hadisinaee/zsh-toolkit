# ============================================================
# SEARCH FUNCTIONS (rg + fzf)
# ============================================================

# ---------------------------------------------------------------------------
# rgg - live interactive grep across files in the current directory
#
# Usage:
#   rgg             open fzf, type to search live
#   rgg <query>     pre-fill query and show matches immediately
#
# Enter opens your configured editor at the exact matched line.
# ---------------------------------------------------------------------------
function rgg() {
  local query="${*:-}"
  local initial_cmd="rg --column --line-number --no-heading --color=always --smart-case"
  local result file line

  result="$(
    fzf --ansi \
        --disabled \
        --query "$query" \
        --bind "start:reload:$initial_cmd {q} || true" \
        --bind "change:reload:$initial_cmd {q} || true" \
        --height=80% --reverse --border \
        --prompt='grep > ' \
        --delimiter=':' \
        --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window='right:50%:wrap:+{2}-5'
  )"

  [[ -z "$result" ]] && return 0

  file="$(echo "$result" | cut -d':' -f1)"
  line="$(echo "$result" | cut -d':' -f2)"
  _zsh_toolkit_open_in_editor +"$line" "$file"
}

# ---------------------------------------------------------------------------
# ff - find files by name using rg + fzf
#
# Usage:
#   ff              list all files in cwd, pick with fzf, open in nvim
#   ff <pattern>    narrow to files matching the pattern (glob-style)
#
# Enter opens the selected file in your configured editor.
# ---------------------------------------------------------------------------
function ff() {
  local file

  if [[ -n "$1" ]]; then
    file="$(rg --files --glob "*${1}*" 2>/dev/null |
      fzf --height=50% --reverse --border --prompt='file > ' \
          --preview 'bat --color=always {}')"
  else
    file="$(rg --files 2>/dev/null |
      fzf --height=50% --reverse --border --prompt='file > ' \
          --preview 'bat --color=always {}')"
  fi

  [[ -n "$file" ]] && _zsh_toolkit_open_in_editor "$file"
}
