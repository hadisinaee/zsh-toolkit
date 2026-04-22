# Resolve the repository root even when this file is sourced via a symlink.
typeset -g ZSH_CONFIG_ROOT="${${(%):-%N}:A:h}"
typeset -g ZSH_TOOLKIT_EDITOR="${ZSH_TOOLKIT_EDITOR:-${VISUAL:-${EDITOR:-vi}}}"

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
  local editor="${ZSH_TOOLKIT_EDITOR:-${VISUAL:-${EDITOR:-vi}}}"
  local -a cmd

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
  ws
)

if (( ! ${+ZSH_CONFIG_MODULES} )); then
  typeset -ga ZSH_CONFIG_MODULES
  ZSH_CONFIG_MODULES=("${_ZSH_CONFIG_DEFAULT_MODULES[@]}")
fi

if (( ! ${+ZSH_CONFIG_DISABLED_MODULES} )); then
  typeset -ga ZSH_CONFIG_DISABLED_MODULES=()
fi

local module file
for module in "${ZSH_CONFIG_MODULES[@]}"; do
  _zsh_config_array_contains "$module" "${ZSH_CONFIG_DISABLED_MODULES[@]}" && continue
  file="$ZSH_CONFIG_ROOT/zsh/${module}.zsh"
  [[ -f "$file" ]] && source "$file"
done

[[ -f "$ZSH_CONFIG_ROOT/zsh/local.zsh" ]] && source "$ZSH_CONFIG_ROOT/zsh/local.zsh"
