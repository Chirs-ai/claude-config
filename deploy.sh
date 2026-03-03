#!/usr/bin/env bash
#
# Claude Code 配置一键部署脚本
# 用法: bash deploy.sh
#
# 将本项目中的 Claude 复用配置部署到当前用户的 ~/.claude/ 目录
# 支持 Linux / macOS / Windows (Git Bash)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code 配置部署 ==="
echo "源目录: $SCRIPT_DIR"
echo "目标: $CLAUDE_DIR"
echo ""

# 检查目标目录
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "创建 $CLAUDE_DIR ..."
    mkdir -p "$CLAUDE_DIR"
fi

# 部署 CLAUDE.md (全局指令)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "[!] CLAUDE.md 已存在，备份为 CLAUDE.md.bak"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
fi
cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "[+] CLAUDE.md"

# 部署 settings.json
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "[!] settings.json 已存在，备份为 settings.json.bak"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
fi
cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "[+] settings.json"

# 部署 commands/
mkdir -p "$CLAUDE_DIR/commands"
for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    filename="$(basename "$cmd_file")"
    if [ -f "$CLAUDE_DIR/commands/$filename" ]; then
        echo "[!] commands/$filename 已存在，备份为 ${filename}.bak"
        cp "$CLAUDE_DIR/commands/$filename" "$CLAUDE_DIR/commands/${filename}.bak"
    fi
    cp "$cmd_file" "$CLAUDE_DIR/commands/$filename"
    echo "[+] commands/$filename"
done

echo ""
echo "=== 部署完成 ==="
echo ""
echo "已部署的配置:"
echo "  CLAUDE.md        - 全局指令 (Git commit 规范、Devlog 开发日志规范)"
echo "  settings.json    - 状态栏、权限设置"
echo "  commands/        - 自定义命令 (gitpush 等)"
