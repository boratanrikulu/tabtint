# tabtint - automatic tab coloring by running process
#
# https://github.com/boratanrikulu/tabtint
#
# Source this file in .zshrc, or use any zsh plugin manager.
# Run `tabtint-init` to create a config, or see `tabtint-help`.

TABTINT_VERSION="0.1.0"

# ── Built-in color palette ───────────────────────────────────────
# Users can add custom colors in their config with: @name = value
typeset -gA _tabtint_palette
_tabtint_palette=(
    # Blues
    blue        "50 120 220"
    indigo      "75 90 200"
    sky         "70 160 235"
    navy        "30 60 150"
    cyan        "40 180 210"

    # Reds / Warm
    red         "200 60 60"
    coral       "230 90 80"
    rose        "210 70 120"
    orange      "230 120 40"
    amber       "220 170 20"
    yellow      "235 200 40"

    # Greens
    green       "50 180 100"
    teal        "50 180 140"
    emerald     "30 150 100"
    lime        "130 200 50"

    # Purples
    purple      "140 70 200"
    violet      "110 60 190"
    magenta     "180 60 160"
    pink        "220 100 160"

    # Neutrals
    slate       "100 116 139"
    graphite    "70 70 80"
)

# ── Terminal backend ─────────────────────────────────────────────
# Dispatches to the right escape sequences based on terminal.
# To add a new terminal: add a case to _tabtint_set and _tabtint_reset.

_tabtint_set() {
    case "${TERM_PROGRAM}" in
        iTerm.app|WezTerm)
            printf "\033]6;1;bg;red;brightness;%s\a" "$1"
            printf "\033]6;1;bg;green;brightness;%s\a" "$2"
            printf "\033]6;1;bg;blue;brightness;%s\a" "$3"
            ;;
    esac
}

_tabtint_reset() {
    case "${TERM_PROGRAM}" in
        iTerm.app|WezTerm)
            printf "\033]6;1;bg;*;default\a"
            ;;
    esac
}

# ── Config ───────────────────────────────────────────────────────
_TABTINT_CONF="${TABTINT_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/tabtint/config}"
_TABTINT_DIR="${0:A:h}"

typeset -gA _tabtint_rules
typeset -ga _tabtint_default_rgb

# Parse color string → sets _r _g _b
_tabtint_parse_color() {
    local val="$1"

    # Named color (built-in + user-defined)
    if [[ -n "${_tabtint_palette[$val]}" ]]; then
        local parts=(${=_tabtint_palette[$val]})
        _r=${parts[1]} _g=${parts[2]} _b=${parts[3]}
        return 0
    fi

    # Hex: #RRGGBB
    if [[ "$val" =~ ^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$ ]]; then
        _r=$(( 16#${match[1]} ))
        _g=$(( 16#${match[2]} ))
        _b=$(( 16#${match[3]} ))
        return 0
    fi

    # CSV: R,G,B
    if [[ "$val" =~ ^([0-9]+),([0-9]+),([0-9]+)$ ]]; then
        _r=${match[1]} _g=${match[2]} _b=${match[3]}
        return 0
    fi

    return 1
}

_tabtint_load() {
    _tabtint_rules=()
    _tabtint_default_rgb=()
    [[ -f "$_TABTINT_CONF" ]] || return

    local line key val _r _g _b color_name
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        key="${line%%=*}"
        val="${line#*=}"
        key="${key// /}"
        val="${val// /}"

        # @name = value → user-defined palette color
        if [[ "$key" == @* ]]; then
            color_name="${key#@}"
            if _tabtint_parse_color "$val"; then
                _tabtint_palette[$color_name]="$_r $_g $_b"
            fi
            continue
        fi

        # default = color → idle tab color (instead of terminal default)
        if [[ "$key" == "default" ]]; then
            if _tabtint_parse_color "$val"; then
                _tabtint_default_rgb=("$_r" "$_g" "$_b")
            fi
            continue
        fi

        # command = color → tab color rule
        if _tabtint_parse_color "$val"; then
            _tabtint_rules[$key]="$_r $_g $_b"
        fi
    done < "$_TABTINT_CONF"
}

# ── Hooks ────────────────────────────────────────────────────────

_tabtint_preexec() {
    local cmd="${1%% *}"
    cmd="${cmd##*/}"

    # sudo/command/exec/nohup/env - match the actual command, not the prefix
    if [[ "$cmd" == (sudo|command|exec|nohup|env|nice|ionice) ]]; then
        local rest="${1#*$cmd }"
        # skip flags (e.g., sudo -u root docker → docker)
        while [[ "$rest" == -* ]]; do
            rest="${rest#* }"
        done
        cmd="${rest%% *}"
        cmd="${cmd##*/}"
    fi

    local rgb="${_tabtint_rules[$cmd]}"
    if [[ -n "$rgb" ]]; then
        _tabtint_set ${=rgb}
    elif (( ${#_tabtint_default_rgb} == 3 )); then
        _tabtint_set "${_tabtint_default_rgb[@]}"
    else
        _tabtint_reset
    fi
}

_tabtint_precmd() {
    # no-op: color persists until the next command
}

# ── Public commands ──────────────────────────────────────────────

tabtint-init() {
    local conf_dir="${_TABTINT_CONF:h}"
    if [[ -f "$_TABTINT_CONF" ]]; then
        echo "tabtint: config already exists at $_TABTINT_CONF"
        return 1
    fi
    mkdir -p "$conf_dir"
    cp "${_TABTINT_DIR}/examples/config" "$_TABTINT_CONF"
    echo "tabtint: created config at $_TABTINT_CONF"
    echo "         edit it, then run tabtint-reload"
}

tabtint-reload() {
    _tabtint_load
    echo "tabtint: loaded ${#_tabtint_rules} rules from $_TABTINT_CONF"
}

tabtint-preview() {
    local name rgb
    echo "Built-in + custom colors:"
    echo ""
    for name in ${(ko)_tabtint_palette}; do
        rgb=(${=_tabtint_palette[$name]})
        printf "  \033[48;2;%s;%s;%sm    \033[0m  %s\n" "${rgb[1]}" "${rgb[2]}" "${rgb[3]}" "$name"
    done
}

tabtint-test() {
    if [[ -z "$1" ]]; then
        echo "usage: tabtint-test <color>"
        echo "       tabtint-test reset"
        return 1
    fi
    if [[ "$1" == "reset" ]]; then
        _tabtint_reset
        return
    fi
    local _r _g _b
    if _tabtint_parse_color "$1"; then
        _tabtint_set "$_r" "$_g" "$_b"
        echo "tabtint: tab set to $1 ($_r,$_g,$_b) - run 'tabtint-test reset' to clear"
    else
        echo "tabtint: unknown color '$1'"
        return 1
    fi
}

tabtint-help() {
    cat <<HELP
tabtint - automatic tab coloring by running process

Commands:
  tabtint-init       Create config from example template
  tabtint-reload     Reload config after editing
  tabtint-preview    Show all available colors
  tabtint-test <c>   Test a color on the current tab
  tabtint-test reset Reset tab to default
  tabtint-help       Show this help

Config: $_TABTINT_CONF
  Override with: export TABTINT_CONFIG=/path/to/config

Config format:
  command = color        Set tab color when command runs
  default = color        Set idle tab color (instead of terminal default)
  @name   = value        Define a custom color name

Color values:
  Named:  indigo, amber, teal, ... (see tabtint-preview)
  Hex:    #RRGGBB
  RGB:    R,G,B

HELP
}

# ── Init ─────────────────────────────────────────────────────────
_tabtint_load

autoload -Uz add-zsh-hook
add-zsh-hook preexec _tabtint_preexec
add-zsh-hook precmd _tabtint_precmd
