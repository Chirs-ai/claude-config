#!/usr/bin/env bash
#
# Ubuntu bootstrap installer for Claude Code / Codex local config.
# Usage: bash bootstrap.sh
#
# Only native Ubuntu performs software installation. Other platforms fall back
# to config sync through deploy.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_MAJOR="${NODE_MAJOR:-22}"
MIN_NODE_MAJOR="${MIN_NODE_MAJOR:-20}"
NPM_GLOBAL_PREFIX="${NPM_GLOBAL_PREFIX:-$HOME/.local/share/npm-global}"
CLAUDE_CODE_FINGERPRINT="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
SUDO=""

log() {
    printf '%s\n' "$*"
}

die() {
    printf '[!] %s\n' "$*" >&2
    exit 1
}

is_wsl() {
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

is_ubuntu() {
    [ -r /etc/os-release ] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    [ "${ID:-}" = "ubuntu" ]
}

ensure_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        return
    fi

    command -v sudo >/dev/null 2>&1 || die "sudo is required for Ubuntu package installation"
    sudo -v
    SUDO="sudo"
}

apt_install() {
    $SUDO apt-get install -y "$@"
}

install_base_deps() {
    log "Installing Ubuntu base dependencies ..."
    $SUDO apt-get update
    apt_install ca-certificates curl gnupg git jq bc
}

configure_claude_apt_repo() {
    local keyring="/etc/apt/keyrings/claude-code.asc"
    local source_file="/etc/apt/sources.list.d/claude-code.list"
    local fingerprint

    $SUDO install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://downloads.claude.ai/keys/claude-code.asc | $SUDO tee "$keyring" >/dev/null

    fingerprint="$(gpg --show-keys --with-colons "$keyring" | awk -F: '$1 == "fpr" { print $10; exit }')"
    [ "$fingerprint" = "$CLAUDE_CODE_FINGERPRINT" ] || die "Claude Code signing key fingerprint mismatch"

    printf '%s\n' \
        "deb [signed-by=$keyring] https://downloads.claude.ai/claude-code/apt/stable stable main" |
        $SUDO tee "$source_file" >/dev/null
}

install_claude_code() {
    if command -v claude >/dev/null 2>&1 && claude --version >/dev/null 2>&1; then
        log "[=] Claude Code already available: $(claude --version)"
        return
    fi

    log "Installing Claude Code from the official apt repository ..."
    configure_claude_apt_repo
    $SUDO apt-get update
    apt_install claude-code
}

current_node_major() {
    node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || printf '0'
}

has_sufficient_node() {
    command -v node >/dev/null 2>&1 || return 1
    command -v npm >/dev/null 2>&1 || return 1
    [ "$(current_node_major)" -ge "$MIN_NODE_MAJOR" ]
}

install_nodesource_node() {
    local keyring="/etc/apt/keyrings/nodesource.gpg"
    local source_file="/etc/apt/sources.list.d/nodesource.list"

    log "Installing Node.js ${NODE_MAJOR}.x from NodeSource ..."
    $SUDO install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
        gpg --dearmor |
        $SUDO tee "$keyring" >/dev/null

    printf 'deb [signed-by=%s] https://deb.nodesource.com/node_%s.x nodistro main\n' \
        "$keyring" "$NODE_MAJOR" |
        $SUDO tee "$source_file" >/dev/null

    $SUDO apt-get update
    apt_install nodejs
}

ensure_profile_path() {
    local file="$1"
    local line

    if [ "$NPM_GLOBAL_PREFIX" = "$HOME/.local/share/npm-global" ]; then
        line='export PATH="$HOME/.local/share/npm-global/bin:$PATH"'
    else
        line="export PATH=\"$NPM_GLOBAL_PREFIX/bin:\$PATH\""
    fi

    touch "$file"
    if ! grep -Fqx "$line" "$file"; then
        {
            printf '\n# npm global binaries\n'
            printf '%s\n' "$line"
        } >> "$file"
    fi
}

configure_npm_prefix() {
    mkdir -p "$NPM_GLOBAL_PREFIX"
    npm config set prefix "$NPM_GLOBAL_PREFIX" >/dev/null
    export PATH="$NPM_GLOBAL_PREFIX/bin:$PATH"

    ensure_profile_path "$HOME/.profile"
    ensure_profile_path "$HOME/.bashrc"
}

install_node_npm() {
    if has_sufficient_node; then
        log "[=] Node.js/npm already available: node $(node --version), npm $(npm --version)"
    else
        install_nodesource_node
    fi

    has_sufficient_node || die "Node.js/npm installation failed or Node.js is older than ${MIN_NODE_MAJOR}.x"
    configure_npm_prefix
}

install_codex_stack() {
    log "Installing/upgrading Codex CLI and ccstatusline ..."
    npm install -g --include=optional @openai/codex@latest ccstatusline@latest
}

verify_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd was not found after installation"
    "$cmd" --version
}

verify_installation() {
    log ""
    log "Verifying CLI installation ..."
    verify_command node
    verify_command npm
    verify_command claude
    verify_command codex
}

bootstrap_ubuntu() {
    ensure_sudo
    install_base_deps
    install_claude_code
    install_node_npm
    install_codex_stack
    verify_installation
}

main() {
    log "=== claude-config bootstrap ==="
    log "Source: $SCRIPT_DIR"

    if is_ubuntu && ! is_wsl; then
        log "Platform: native Ubuntu"
        bootstrap_ubuntu
    else
        log "Platform is not native Ubuntu; skipping software installation."
    fi

    log ""
    log "Syncing Claude/Codex config ..."
    bash "$SCRIPT_DIR/deploy.sh"

    log ""
    log "Bootstrap complete. Run 'claude' and 'codex' once to finish account authentication."
}

main "$@"
