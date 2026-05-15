#!/usr/bin/env bash
#
# Native Ubuntu entrypoint for bootstrapping this repository from a bare host.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Chirs-ai/claude-config/main/install-ubuntu.sh -o /tmp/claude-config-install-ubuntu.sh
#   bash /tmp/claude-config-install-ubuntu.sh

set -euo pipefail

REPO_URL="${CLAUDE_CONFIG_REPO_URL:-https://github.com/Chirs-ai/claude-config.git}"
TARGET_DIR="${CLAUDE_CONFIG_DIR:-$HOME/projects/claude-config}"
SUDO=""

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

ensure_native_ubuntu() {
    is_ubuntu || die "install-ubuntu.sh only supports Ubuntu"
    ! is_wsl || die "WSL is intentionally excluded; run deploy.sh from the cloned repo instead"
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

install_fetch_deps() {
    $SUDO apt-get update
    $SUDO apt-get install -y ca-certificates git
}

sync_repo() {
    if [ -d "$TARGET_DIR/.git" ]; then
        git -C "$TARGET_DIR" pull --ff-only
        return
    fi

    if [ -e "$TARGET_DIR" ]; then
        die "$TARGET_DIR already exists but is not a git repository"
    fi

    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
}

main() {
    ensure_native_ubuntu
    ensure_sudo
    install_fetch_deps
    sync_repo
    bash "$TARGET_DIR/bootstrap.sh"
}

main "$@"
