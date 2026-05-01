# Resolve the repository root even when this file is sourced via a symlink.
typeset -g ZSH_CONFIG_ROOT="${${(%):-%N}:A:h}"

function _zsh_toolkit_resolve_editor() {
  if [[ -n "${ZSH_TOOLKIT_EDITOR:-}" ]]; then
    printf '%s\n' "$ZSH_TOOLKIT_EDITOR"
    return
  fi

  if [[ -n "${EDITOR:-}" ]]; then
    printf '%s\n' "$EDITOR"
    return
  fi

  if [[ -n "${VISUAL:-}" ]]; then
    printf '%s\n' "$VISUAL"
    return
  fi

  if command -v nvim >/dev/null 2>&1; then
    printf '%s\n' "nvim"
    return
  fi

  printf '%s\n' "vi"
}

typeset -g ZSH_TOOLKIT_EDITOR="$(_zsh_toolkit_resolve_editor)"

function _zsh_config_array_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done

  return 1
}

function _zsh_toolkit_open_in_editor() {
  local editor
  local -a cmd

  editor="$(_zsh_toolkit_resolve_editor)"
  cmd=(${(z)editor})
  "${cmd[@]}" "$@"
}

typeset -ga _ZSH_CONFIG_DEFAULT_MODULES=(
  shell
  tools
  git
  k8s
  til
  search
  zt
  ws
  bm
  sec
)

# Load shared state helpers before modules that rely on file mutation helpers.
[[ -f "$ZSH_CONFIG_ROOT/zsh/state.zsh" ]] && source "$ZSH_CONFIG_ROOT/zsh/state.zsh"

# Respect a user-pinned list (ZSH_CONFIG_MODULES set before sourcing this file),
# but always refresh from defaults on re-source so new modules are picked up.
if (( ! ${+ZSH_CONFIG_MODULES_PINNED} )); then
  typeset -ga ZSH_CONFIG_MODULES
  ZSH_CONFIG_MODULES=("${_ZSH_CONFIG_DEFAULT_MODULES[@]}")
fi

if (( ! ${+ZSH_CONFIG_DISABLED_MODULES} )); then
  typeset -ga ZSH_CONFIG_DISABLED_MODULES=()
fi

function _zsh_toolkit_load_modules() {
  local module file

  for module in "${ZSH_CONFIG_MODULES[@]}"; do
    _zsh_config_array_contains "$module" "${ZSH_CONFIG_DISABLED_MODULES[@]}" && continue
    file="$ZSH_CONFIG_ROOT/zsh/${module}.zsh"
    [[ -f "$file" ]] && source "$file"
  done
}

_zsh_toolkit_load_modules

function _zsh_toolkit_load_local_overrides() {
  emulate -L zsh

  local local_dir="$ZSH_CONFIG_ROOT/zsh/local.d"
  local file

  for file in "$local_dir"/*.zsh(.N); do
    source "$file"
  done

  [[ -f "$ZSH_CONFIG_ROOT/zsh/local.zsh" ]] && source "$ZSH_CONFIG_ROOT/zsh/local.zsh"
}

_zsh_toolkit_load_local_overrides
