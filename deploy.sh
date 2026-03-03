#!/usr/bin/env bash
#
# Claude Code 配置一键部署脚本
# 用法: bash deploy.sh
#
# 支持: Linux (Ubuntu) / macOS / Windows (Git Bash / WSL)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 检测平台与 Claude 配置目录 ──
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                PLATFORM="WSL"
                # WSL 中 $HOME 指向 Linux home，Claude Code 装在 Windows 侧
                WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')
                CLAUDE_DIR="/mnt/c/Users/${WIN_USER}/.claude"
            else
                PLATFORM="Linux"
                CLAUDE_DIR="$HOME/.claude"
            fi
            ;;
        Darwin*)
            PLATFORM="macOS"
            CLAUDE_DIR="$HOME/.claude"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM="Windows (Git Bash)"
            CLAUDE_DIR="$HOME/.claude"
            ;;
        *)
            PLATFORM="Unknown ($(uname -s))"
            CLAUDE_DIR="$HOME/.claude"
            ;;
    esac
}

detect_platform

echo "=== Claude Code 配置部署 ==="
echo "平台:   $PLATFORM"
echo "源目录: $SCRIPT_DIR"
echo "目标:   $CLAUDE_DIR"
echo ""

# ── 创建目标目录 ──
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "创建 $CLAUDE_DIR ..."
    mkdir -p "$CLAUDE_DIR"
fi

# ── 部署单个文件的通用函数 ──
deploy_file() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ -f "$dst" ]; then
        if diff -q "$src" "$dst" > /dev/null 2>&1; then
            echo "[=] $label (无变化，跳过)"
            return
        fi
        echo "[!] $label 已存在，备份为 ${label}.bak"
        cp "$dst" "${dst}.bak"
    fi
    cp "$src" "$dst"
    echo "[+] $label"
}

# ── 部署配置文件 ──
deploy_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
deploy_file "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"

# ── 部署 commands/ ──
mkdir -p "$CLAUDE_DIR/commands"
for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    filename="$(basename "$cmd_file")"
    deploy_file "$cmd_file" "$CLAUDE_DIR/commands/$filename" "commands/$filename"
done

echo ""
echo "=== 部署完成 ==="
echo ""
echo "已部署的配置:"
echo "  CLAUDE.md        - 全局指令 (Git commit 规范、Devlog 开发日志规范)"
echo "  settings.json    - 状态栏、权限设置"
echo "  commands/        - 自定义命令 (gitpush 等)"
