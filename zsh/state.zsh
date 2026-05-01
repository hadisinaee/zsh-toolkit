# Shared helpers for tiny key=value state files.

function _zsh_toolkit_kv_update_file() {
  emulate -L zsh

  local file="$1"
  local key="$2"
  local value="${3:-}"
  local mode="${4:-set}"  # set | delete
  local tmp found=0 line current_key

  tmp="$(/usr/bin/mktemp "${file}.XXXXXX")" || return 1

  {
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ -z "$line" || "$line" == \#* ]]; then
        printf '%s\n' "$line"
        continue
      fi

      current_key="${line%%=*}"
      if [[ "$current_key" == "$key" ]]; then
        found=1
        [[ "$mode" == "delete" ]] && continue
        printf '%s=%s\n' "$key" "$value"
        continue
      fi

      printf '%s\n' "$line"
    done < "$file"

    if [[ "$mode" == "set" && $found -eq 0 ]]; then
      printf '%s=%s\n' "$key" "$value"
    fi
  } > "$tmp" || {
    /bin/rm -f "$tmp"
    return 1
  }

  /bin/mv "$tmp" "$file" || {
    /bin/rm -f "$tmp"
    return 1
  }
}
