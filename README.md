# tabtint

Automatic terminal tab coloring based on the running command.

Type `ssh` and the tab turns red. Run `kubectl` and it turns teal. When the command finishes, the color resets. No manual setup per-tab - just a simple config file.

<!-- TODO: add GIF demo here -->
<!-- ![tabtint demo](demo.gif) -->

## Supported Terminals

- [iTerm2](https://iterm2.com/)
- [WezTerm](https://wezfurlong.org/wezterm/)

PRs welcome for other terminals - see [Adding a terminal backend](#adding-a-terminal-backend).

## Install

### Plugin manager (recommended)

Works with any zsh plugin manager - they all just source a `.zsh` file.

<details>
<summary><strong>zinit</strong></summary>

```zsh
zinit light boratanrikulu/tabtint
```
</details>

<details>
<summary><strong>oh-my-zsh</strong></summary>

```bash
git clone https://github.com/boratanrikulu/tabtint.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/tabtint
```

Add to `.zshrc`:
```zsh
plugins=(... tabtint)
```
</details>

<details>
<summary><strong>antigen</strong></summary>

```zsh
antigen bundle boratanrikulu/tabtint
```
</details>

<details>
<summary><strong>sheldon</strong></summary>

```toml
[plugins.tabtint]
github = "boratanrikulu/tabtint"
```
</details>

### Manual

```bash
git clone https://github.com/boratanrikulu/tabtint.git ~/.tabtint
echo 'source ~/.tabtint/tabtint.zsh' >> ~/.zshrc
```

## Quick Start

```bash
tabtint-init       # creates ~/.config/tabtint/config from the example
```

Edit the config to match your workflow, then `tabtint-reload`.

## Configure

The config lives at `~/.config/tabtint/config` (follows XDG). Override with:

```zsh
export TABTINT_CONFIG="$HOME/.tabtint.conf"
```

### Rules

One rule per line - when you run `command`, the tab changes to `color`:

```
ssh     = red
kubectl = teal
claude  = indigo
```

### Colors

| Format | Example | Notes |
|--------|---------|-------|
| Named  | `indigo` | Run `tabtint-preview` to see all |
| Hex    | `#E05050` | Standard 6-digit hex |
| RGB    | `100,200,150` | Comma-separated, 0-255 |

### Custom colors

Define your own named colors with `@`, then use them like built-ins:

```
@solarblue = #268BD2
@dracula   = 189,147,249

claude     = solarblue
ssh        = dracula
```

Custom colors survive plugin updates - they live in your config, not the source.

### Idle tab color

By default, tabs reset to the terminal's default color when a command finishes. Set `default` to use a persistent base color instead:

```
default = graphite
```

## Commands

| Command | Description |
|---------|-------------|
| `tabtint-init` | Create config from example template |
| `tabtint-reload` | Reload config without restarting the shell |
| `tabtint-preview` | Show all named colors (built-in + custom) |
| `tabtint-test <color>` | Set current tab to a color for testing |
| `tabtint-test reset` | Reset tab to default |
| `tabtint-help` | Quick reference |

## Built-in Colors

| | | | |
|---|---|---|---|
| `blue` | `indigo` | `sky` | `navy` |
| `cyan` | `red` | `coral` | `rose` |
| `orange` | `amber` | `yellow` | `green` |
| `teal` | `emerald` | `lime` | `purple` |
| `violet` | `magenta` | `pink` | `slate` |
| `graphite` | | | |

## Requirements

- zsh 5.1+ (for `add-zsh-hook` and associative arrays)
- A supported terminal: iTerm2 3.0+, WezTerm

## Powerlevel10k

If you use Powerlevel10k with instant prompt, source tabtint **after** p10k:

```zsh
# ✅ correct - after p10k init
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/.tabtint/tabtint.zsh    # or via plugin manager

# ❌ wrong - between instant prompt and p10k theme load
```

If placed correctly and you still see warnings, please [open an issue](https://github.com/boratanrikulu/tabtint/issues).

## How It Works

tabtint uses zsh's `preexec` hook to set the tab color before each command:

- **Matched command** → tab turns that color and **stays** until the next command
- **Unmatched command** → tab resets to default (or to `default` color if configured)

```
kubectl get pods  → tab turns teal, stays teal after it finishes
ls                → tab resets (no rule)
ssh server        → tab turns red, stays red while connected
```

Commands prefixed with `sudo`, `env`, `nohup`, etc. are handled - `sudo docker ps` matches `docker`, not `sudo`.

No background processes, no polling, no dependencies.

## Adding a Terminal Backend

The terminal-specific code lives in two functions in `tabtint.zsh`:

```zsh
_tabtint_set()    # receives R G B (0-255), sets the tab color
_tabtint_reset()  # resets tab color to default
```

Both dispatch on `$TERM_PROGRAM`. To add a new terminal, add a case with its escape sequences. PRs welcome.

## Uninstall

1. Remove the source line or plugin entry from `.zshrc`
2. Optionally remove your config: `rm -rf ~/.config/tabtint`
3. Remove the plugin: `rm -rf ~/.tabtint` (or wherever you cloned it)

## License

[MIT](LICENSE)
