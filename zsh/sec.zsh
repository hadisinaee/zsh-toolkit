typeset -g SEC_FILE="$ZSH_CONFIG_ROOT/zsh/secrets"
[[ -f "$SEC_FILE" ]] || touch "$SEC_FILE"

# Auto-export all secrets as env vars at init
while IFS='=' read -r _sec_name _sec_val; do
  [[ -z "$_sec_name" || "$_sec_name" == \#* ]] && continue
  export "${_sec_name}=${_sec_val}"
done < "$SEC_FILE"
unset _sec_name _sec_val

function sec() {
  case "$1" in
    add) _sec_add "${@:2}" ;;
    rm)  _sec_rm ;;
    ls)  _sec_ls ;;
    *)   _sec_pick ;;
  esac
}

function _sec_keys() {
  cut -d= -f1 "$SEC_FILE" | grep -v '^[[:space:]]*#' | grep -v '^$'
}

# fzf picker — keys only
# Enter → copy value to clipboard; Ctrl-e → export in current shell; Ctrl-y → copy key
function _sec_pick() {
  local out action key val

  out=$(_sec_keys | fzf --prompt="secret> " \
    --expect=ctrl-e,ctrl-y \
    --height=40% --layout=reverse \
    --header='Enter: copy value | Ctrl-e: export | Ctrl-y: copy key')

  [[ -z "$out" ]] && return
  action=$(head -1 <<< "$out")
  key=$(tail -1 <<< "$out")
  [[ -z "$key" ]] && return
  val=$(grep "^${key}=" "$SEC_FILE" | cut -d= -f2-)
  if [[ "$action" == "ctrl-e" ]]; then
    export "${key}=${val}"
    echo "exported: $key"
  elif [[ "$action" == "ctrl-y" ]]; then
    printf '%s' "$key" | pbcopy
    echo "copied key: $key"
  else
    printf '%s' "$val" | pbcopy
    echo "copied: $key"
  fi
}

# add secret; prompts silently if value not provided
function _sec_add() {
  local name="$1" val="$2"
  [[ -z "$name" ]] && { echo "usage: sec add NAME [value]"; return 1 }
  if [[ -z "$val" ]]; then
    printf 'value for %s: ' "$name"
    read -rs val
    echo
  fi
  _zsh_toolkit_kv_update_file "$SEC_FILE" "$name" "$val" set
  export "${name}=${val}"
  echo "saved: $name"
}

# remove via fzf picker
function _sec_rm() {
  local name
  name=$(_sec_keys | fzf --prompt="remove secret> ")
  [[ -z "$name" ]] && return
  _zsh_toolkit_kv_update_file "$SEC_FILE" "$name" "" delete
  unset "$name"
  echo "removed: $name"
}

# list key names only
function _sec_ls() {
  _sec_keys
}
