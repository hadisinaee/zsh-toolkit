# ============================================================
# KUBERNETES
# ============================================================

alias k="kubectl"

function kctx-usage() {
  echo "kctx - kubectl context switcher"
  echo
  echo "Usage:"
  echo "  kctx           open the context picker"
  echo "  kctx <name>    switch directly to a context"
  echo "  kctx -         switch to the previous context"
  echo "  kctx -d [name] delete a context"
}

# ---------------------------------------------------------------------------
# kctx - switch kubectl context, with fzf picker when no args given
#
# Usage:
#   kctx              fzf picker over all contexts
#   kctx <name>       switch directly to named context
#   kctx -            switch to previous context
#   kctx -d [name]    delete context (fzf picker if no name given)
# ---------------------------------------------------------------------------
function kctx() {
  case "${1:-}" in
    help|-h|--help) kctx-usage; return 0 ;;
  esac

  local current
  current="$(kubectl config current-context 2>/dev/null)"

  if [[ "$1" == "-" ]]; then
    local prev
    prev="$(kubectl config view -o jsonpath='{.contexts[*].name}' 2>/dev/null |
      tr ' ' '\n' | grep -v "^${current}$" | tail -1)"
    if [[ -z "$prev" ]]; then
      echo "kctx: no previous context found"
      return 1
    fi
    kubectl config use-context "$prev"
    return
  fi

  if [[ "$1" == "-d" ]]; then
    local ctx
    if [[ -n "$2" ]]; then
      ctx="$2"
    else
      ctx="$(kubectl config get-contexts -o name 2>/dev/null |
        fzf --height=40% --reverse --border --prompt='delete context > ' \
            --preview 'kubectl config get-contexts {}')"
    fi
    [[ -z "$ctx" ]] && return 0
    kubectl config delete-context "$ctx"
    return
  fi

  if [[ -n "$1" ]]; then
    kubectl config use-context "$1"
    return
  fi

  local ctx
  ctx="$(kubectl config get-contexts -o name 2>/dev/null |
    awk -v cur="$current" '{
      if ($0 == cur) print "* " $0
      else print "  " $0
    }' |
    fzf --height=40% --reverse --border --prompt='context > ' \
        --ansi \
        --preview 'kubectl config get-contexts {-1}' |
    awk '{print $NF}')"

  [[ -n "$ctx" ]] && kubectl config use-context "$ctx"
}
