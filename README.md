# zsh-toolkit

<p align="center">
  <img src="assets/zsh-toolkit.png" alt="zsh-toolkit logo" width="320">
</p>

A small Zsh toolkit you source from your existing `~/.zshrc`.

## Quick start

1. Clone the repo somewhere stable:
   ```sh
   git clone <repo-url> ~/Projects/zsh-toolkit
   ```
2. Install the required tools:
   ```sh
   ~/Projects/zsh-toolkit/scripts/install.sh
   ```
3. Add this near the end of your `~/.zshrc`:
   ```zsh
   source ~/Projects/zsh-toolkit/init.zsh
   ```
4. Create your personal override file:
   ```sh
   cp ~/Projects/zsh-toolkit/zsh/local.example.zsh ~/Projects/zsh-toolkit/zsh/local.zsh
   ```
5. Reload your shell:
   ```sh
   source ~/.zshrc
   ```

## How it works

- `init.zsh` loads the shared toolkit.
- `zsh/*.zsh` contains the tracked modules.
- `zsh/local.zsh` is your ignored personal file.
- `zsh/local.d/*.zsh` is an optional ignored split-file layer for larger local setups.

Keep reusable defaults in tracked modules. Keep personal aliases, PATH changes, secrets, and machine-specific settings in `zsh/local.zsh` or, if you want to split them up, `zsh/local.d/*.zsh`.

## Personal overrides

`init.zsh` loads local overrides in this order:

1. shared tracked modules
2. optional `zsh/local.d/*.zsh` files, in lexical order
3. `zsh/local.zsh`

That keeps `zsh/local.zsh` as the final override file.

```zsh
# zsh/local.zsh
export PATH="$HOME/.local/bin:$PATH"
alias gs='git status'
```

If your local config gets large, you can split it by topic:

```sh
mkdir -p ~/Projects/zsh-toolkit/zsh/local.d
```

```zsh
# zsh/local.d/work.zsh
export WORKON_HOME="$HOME/venvs"
```

```zsh
# zsh/local.d/aliases.zsh
alias gs='git status'
```

Editor-based helpers use `ZSH_TOOLKIT_EDITOR`, then `EDITOR`, then `VISUAL`, then `nvim` when available, with `vi` as the final fallback.

Use `zt help` as the canonical toolkit help entrypoint, and `zt help <command>` for command-specific usage.

In the `til` and `todo` pickers, press `Ctrl-N` to create a new note from the current query.

## Modules

The default modules are:

- `shell`
- `tools`
- `git`
- `k8s`
- `til`
- `search`
- `zt`
- `ws`
- `bm`
- `sec`

If you want fewer modules, set this before sourcing `init.zsh`:

```zsh
typeset -ga ZSH_CONFIG_DISABLED_MODULES=(k8s ws)
source ~/Projects/zsh-toolkit/init.zsh
```

If you want full control, set the full list yourself:

```zsh
typeset -ga ZSH_CONFIG_MODULES=(shell tools git search)
source ~/Projects/zsh-toolkit/init.zsh
```

## Required tools

`scripts/install.sh` installs the shared toolchain with Homebrew:

- `fzf`
- `bat`
- `ripgrep`
- `tmux`
- `kubectl`
- `starship`
- `mise`
- `terraform`

The install script currently supports macOS + Homebrew only.

## tmux setup (macOS)

On macOS, new tmux sessions do not source `/etc/zprofile`, so `path_helper` never runs and PATH is nearly empty — tools like `fzf` and even `grep` will not be found inside sessions created by `ws`.

Add this to `~/.tmux.conf` to start all panes as login shells:

```
set-option -g default-command "zsh -l"
```

Then reload tmux config (`tmux source ~/.tmux.conf`) or restart tmux.
