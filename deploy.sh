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

# ── 检查并安装系统依赖 ──
install_deps() {
    local missing=()
    command -v jq  > /dev/null 2>&1 || missing+=(jq)
    command -v bc  > /dev/null 2>&1 || missing+=(bc)

    if [ ${#missing[@]} -eq 0 ]; then
        echo "[=] 系统依赖已就绪 (jq, bc)"
        return
    fi

    echo "缺少依赖: ${missing[*]}"

    case "$PLATFORM" in
        Linux|WSL)
            if command -v apt-get > /dev/null 2>&1; then
                echo "通过 apt 安装 ${missing[*]} ..."
                sudo apt-get update -qq && sudo apt-get install -y -qq "${missing[@]}"
            elif command -v yum > /dev/null 2>&1; then
                echo "通过 yum 安装 ${missing[*]} ..."
                sudo yum install -y "${missing[@]}"
            else
                echo "[!] 无法自动安装，请手动安装: ${missing[*]}"
                return 1
            fi
            ;;
        macOS)
            if command -v brew > /dev/null 2>&1; then
                echo "通过 brew 安装 ${missing[*]} ..."
                brew install "${missing[@]}"
            else
                echo "[!] 未检测到 Homebrew，请先安装: https://brew.sh"
                echo "    然后运行: brew install ${missing[*]}"
                return 1
            fi
            ;;
        "Windows (Git Bash)")
            echo "[!] Git Bash 下请手动安装缺少的工具:"
            for dep in "${missing[@]}"; do
                case "$dep" in
                    jq) echo "    jq: https://jqlang.github.io/jq/download/" ;;
                    bc) echo "    bc: pacman -S bc (若使用 MSYS2)" ;;
                esac
            done
            return 1
            ;;
    esac

    echo "[+] 依赖安装完成 (${missing[*]})"
}

install_deps || true
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
deploy_file "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh" "statusline.sh"

# ── 部署 commands/ ──
mkdir -p "$CLAUDE_DIR/commands"
for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    filename="$(basename "$cmd_file")"
    deploy_file "$cmd_file" "$CLAUDE_DIR/commands/$filename" "commands/$filename"
done

# ── 部署 templates/ ──
mkdir -p "$CLAUDE_DIR/templates"
for tpl_file in "$SCRIPT_DIR/templates"/*; do
    [ -f "$tpl_file" ] || continue
    filename="$(basename "$tpl_file")"
    deploy_file "$tpl_file" "$CLAUDE_DIR/templates/$filename" "templates/$filename"
done

# ── 安装 ccstatusline ──
echo ""
if command -v npm > /dev/null 2>&1; then
    if npm list -g ccstatusline > /dev/null 2>&1; then
        echo "[=] ccstatusline 已安装 ($(npm list -g ccstatusline 2>/dev/null | grep ccstatusline | sed 's/.*@/v/'))"
    else
        echo "安装 ccstatusline ..."
        npm install -g ccstatusline && echo "[+] ccstatusline" || echo "[!] ccstatusline 安装失败，settings.json 中的 npx 会在首次使用时自动下载"
    fi
else
    echo "[!] 未检测到 npm，跳过 ccstatusline 安装"
    echo "    请先安装 Node.js，或后续通过 npx 自动下载"
fi

echo ""
echo "=== 部署完成 ==="
echo ""
echo "已部署的配置:"
echo "  CLAUDE.md        - 全局指令 (Git commit 规范、Devlog 开发日志规范)"
echo "  settings.json    - 状态栏、权限设置"
echo "  statusline.sh    - 自定义状态栏脚本 (备用)"
echo "  commands/        - 自定义命令 (gitpush, deploy, deploy-init 等)"
echo "  templates/       - 部署模板 (server.secret, run.sh)"
echo "  ccstatusline     - npm 状态栏工具"
