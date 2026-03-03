# Claude Code 复用配置

跨项目、跨环境复用的 Claude Code 个人配置集合。克隆本仓库后运行部署脚本即可在新机器上还原全部配置。

## 仓库结构

```
claude-config/
├── CLAUDE.md              # 全局指令（部署到 ~/.claude/CLAUDE.md）
├── settings.json          # Claude Code 设置（部署到 ~/.claude/settings.json）
├── commands/              # 自定义斜杠命令（部署到 ~/.claude/commands/）
│   └── gitpush.md         #   /gitpush - 一键 commit + push
├── deploy.sh              # 一键部署脚本
└── README.md
```

## 快速部署

### 前置条件

- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`npm install -g @anthropic-ai/claude-code`）
- Git Bash（Windows）或 Bash（Linux / macOS）

### 新环境部署

```bash
# 1. 克隆仓库
git clone <repo-url> claude-config
cd claude-config

# 2. 一键部署
bash deploy.sh
```

部署脚本会将配置文件复制到 `~/.claude/` 目录。如果目标位置已有同名文件，会自动备份为 `.bak` 再覆盖，不会丢失原有配置。

### 部署输出示例

```
=== Claude Code 配置部署 ===
源目录: /d/projects/claude-config
目标: /c/Users/Administrator/.claude

[+] CLAUDE.md
[+] settings.json
[+] commands/gitpush.md

=== 部署完成 ===
```

## 配置说明

### CLAUDE.md — 全局指令

所有项目中 Claude Code 自动加载的行为规范：

| 规则 | 说明 |
|------|------|
| Git commit 规范 | 不添加 Co-Authored-By 行 |
| Devlog 开发日志 | 非平凡任务在项目 `devlog/` 目录记录分析和方案 |
| Devlog 文件命名 | `YYYY-MM-DD-HHMM-语义描述.md`（如 `2026-03-03-1530-storage-analysis.md`） |

### settings.json — 运行时设置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `statusLine` | `ccstatusline` | 终端状态栏显示 Git 分支、token 用量等信息 |
| `skipDangerousModePermissionPrompt` | `true` | 跳过危险模式的二次确认弹窗 |

### commands/gitpush.md — 自定义命令

在 Claude Code 中输入 `/gitpush` 触发，自动执行：

1. `git status` + `git diff` 检查变更
2. 参考项目历史风格生成 commit message
3. `git add -A` → `git commit` → `git push`

## 维护与同步

### 新增配置

```bash
# 在本仓库中添加新的自定义命令
# 例如新增 /review 命令
vim commands/review.md

# 提交并推送
git add -A && git commit -m "新增 /review 命令" && git push
```

### 同步到其他机器

```bash
cd claude-config
git pull
bash deploy.sh
```

### 新增配置类型

如需添加新的配置类型（如 hooks、keybindings），步骤：

1. 在仓库中创建对应文件
2. 在 `deploy.sh` 中添加对应的复制逻辑
3. 更新本 README 的配置说明

## 注意事项

- `settings.json` 中的 `skipDangerousModePermissionPrompt` 会跳过风险操作确认，新环境中请根据需要调整
- 部署脚本不会复制 `.credentials.json`、`history.jsonl` 等敏感或会话数据
- 每台机器的 Claude Code 登录凭证需单独通过 `claude login` 获取
