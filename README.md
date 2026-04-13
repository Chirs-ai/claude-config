# Claude Code 复用配置

跨项目、跨环境复用的 Claude Code 个人配置集合。克隆本仓库后运行部署脚本即可在新机器上还原全部配置。

## 仓库结构

```
claude-config/
├── CLAUDE.md              # 全局指令（部署到 ~/.claude/CLAUDE.md）
├── settings.json          # Claude Code 设置（部署到 ~/.claude/settings.json）
├── statusline.sh          # 自定义状态栏脚本（部署到 ~/.claude/statusline.sh）
├── commands/              # 自定义斜杠命令（部署到 ~/.claude/commands/）
│   ├── gitpush.md         #   /gitpush - 一键 commit + push
│   ├── deploy.md          #   /deploy  - 一键部署到远程服务器
│   ├── deploy-init.md     #   /deploy-init - 初始化项目部署配置
│   ├── regression-check.md #  /regression-check - 回归验证
│   ├── save-devlog.md     #   /save-devlog - 保存开发日志
│   └── socratic-writing.md #  /socratic-writing - 苏格拉底式文章创作
├── templates/             # 部署模板（部署到 ~/.claude/templates/）
│   ├── server.secret.template  # 服务器连接信息模板
│   └── run.sh.template         # 服务管理脚本模板
├── .gitattributes         # 跨平台换行符控制（.sh 强制 LF）
├── deploy.sh              # 部署脚本 - Linux / macOS / Git Bash / WSL
├── deploy.ps1             # 部署脚本 - PowerShell (Windows / macOS / Linux)
├── deploy.bat             # 部署入口 - Windows 双击运行
└── README.md
```

## 快速部署

### 前置条件

- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`npm install -g @anthropic-ai/claude-code`）
- Git
- Node.js / npm（部署脚本会自动安装 `ccstatusline`）

### 系统依赖（部署脚本自动处理）

备用状态栏脚本 `statusline.sh` 依赖 `jq` 和 `bc`，部署脚本会自动检测并安装：

| 平台 | 自动安装方式 |
|------|-------------|
| **Ubuntu / Debian** | `sudo apt-get install jq bc` |
| **CentOS / RHEL** | `sudo yum install jq bc` |
| **macOS** | `brew install jq bc`（需先装 [Homebrew](https://brew.sh)） |
| **Windows** | 主状态栏 `ccstatusline` 不依赖这些，可忽略 |

> 如果不使用备用 `statusline.sh`，缺少 `jq`/`bc` 不影响其他功能。

### 各平台部署方式

```bash
# 1. 克隆仓库（所有平台通用）
git clone <repo-url> claude-config
cd claude-config
```

| 平台 | 部署命令 |
|------|---------|
| **Ubuntu / Linux** | `bash deploy.sh` |
| **macOS** | `bash deploy.sh` |
| **Windows (Git Bash)** | `bash deploy.sh` |
| **Windows (PowerShell)** | `powershell -ExecutionPolicy Bypass -File deploy.ps1` |
| **Windows (双击)** | 直接双击 `deploy.bat` |
| **WSL** | `bash deploy.sh`（自动定位 Windows 侧 `~/.claude`） |

### 部署行为

- 配置文件复制到 `~/.claude/` 目录（Windows 上为 `%USERPROFILE%\.claude\`）
- 已有同名文件自动备份为 `.bak`，不会丢失原有配置
- 内容无变化的文件自动跳过，不重复覆盖
- 自动检测并安装 `ccstatusline` npm 包（需要 Node.js）

### 部署输出示例

```
=== Claude Code 配置部署 ===
平台:   Windows (Git Bash)
源目录: /d/projects/claude-config
目标:   /c/Users/Administrator/.claude

[+] CLAUDE.md
[=] settings.json (无变化，跳过)
[+] statusline.sh
[+] commands/gitpush.md

[=] ccstatusline 已安装 (v2.0.23)

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

### 状态栏 (statusline)

部署脚本会自动处理两层保障：

1. **`ccstatusline` npm 包**（主要）：全局安装，`settings.json` 中通过 `npx -y ccstatusline@latest` 调用，显示模型名称、token 用量、费用、上下文占比等信息
2. **`statusline.sh` 脚本**（备用）：自定义 bash 脚本，可在 `settings.json` 中切换使用

如需切换到备用脚本，修改 `settings.json`：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

### commands/ — 自定义命令

#### /gitpush — 一键提交推送

在 Claude Code 中输入 `/gitpush` 触发，自动执行：

1. `git status` + `git diff` 检查变更
2. 参考项目历史风格生成 commit message
3. `git add -A` → `git commit` → `git push`

#### /deploy — 一键部署到远程服务器

在 Claude Code 中输入 `/deploy` 触发，自动完成远程服务器部署。

**工作流程：**

```
前置检查 → SSH 连接 → 检测目录 → git pull / clone → 重启服务 → 验证状态 → 清理
```

1. 读取项目根目录的 `.server.secret` 获取服务器 IP、用户名、部署路径
2. 读取私钥到临时文件并设置权限
3. SSH 到服务器检查部署目录是否存在：
   - **已存在** → `git pull` → `./run.sh restart` → `./run.sh status`
   - **不存在** → 自动 `git clone`（从本地 git remote 获取 URL）→ 提示用户完成首次环境配置
4. 删除临时密钥文件
5. 向用户报告部署结果

**业务项目接入要求：**

每个需要远程部署的项目，只需在项目根目录准备两个文件：

**1. `.server.secret`** — 服务器连接信息（必须加入 `.gitignore`）

```
server ip:

192.168.1.100

root


deploy path:

/opt/my-project


privatekey:

-----BEGIN RSA PRIVATE KEY-----
<私钥内容>
-----END RSA PRIVATE KEY-----
```

| 字段 | 必填 | 说明 |
|------|------|------|
| server ip | 是 | 服务器 IP 地址或域名 |
| 用户名 | 是 | SSH 登录用户名（紧跟在 IP 下方） |
| deploy path | 否 | 服务器上的部署路径，默认 `~/<本地项目目录名>` |
| privatekey | 是 | SSH 私钥 |

**2. `run.sh`** — 服务管理脚本，至少支持以下子命令：

| 子命令 | 说明 |
|--------|------|
| `start` | 启动服务 |
| `stop` | 停止服务 |
| `restart` | 重启服务 |
| `status` | 查看运行状态 |

`run.sh` 的具体实现因项目而异（conda/venv/docker/直接运行等），只需遵循统一的子命令接口即可。

**3. `.gitignore`** — 确保包含 `.server.secret`

```gitignore
.server.secret
```

**新项目接入（推荐使用 /deploy-init）：**

```bash
# 第 1 步：交互式生成 .server.secret + run.sh（自动更新 .gitignore）
/deploy-init

# 第 2 步：编辑 .server.secret，粘贴 SSH 私钥
vim .server.secret

# 第 3 步：一键部署（首次自动 git clone，后续自动 git pull + restart）
/deploy
```

**手动接入（不使用 /deploy-init）：**

```bash
vim .server.secret          # 按模板格式填写
vim run.sh                  # 从 ~/.claude/templates/run.sh.template 复制修改
echo ".server.secret" >> .gitignore
/deploy
```

**安全设计：**

- `.server.secret` 不入 Git 仓库，仅存在于本地开发机
- SSH 私钥仅在部署期间写入 `/tmp`，使用后立即删除
- 迁移到新机器时，需手动将 `.server.secret` 复制到各项目目录

#### /deploy-init — 初始化项目部署配置

在 Claude Code 中输入 `/deploy-init` 触发，为当前项目生成部署所需的配置文件。

**工作流程：**

1. 检查项目中是否已存在 `.server.secret` 和 `run.sh`，已存在则跳过
2. 从 `~/.claude/templates/` 读取模板，交互式询问配置：
   - 服务器 IP、用户名、部署路径 → 生成 `.server.secret`
   - 入口文件名、环境类型、环境名称 → 生成 `run.sh`
3. 自动更新 `.gitignore`（添加 `.server.secret`、`app.log`、`app.pid`）
4. 提示用户编辑 `.server.secret` 粘贴 SSH 私钥

**新项目完整接入流程：**

```bash
# 第 1 步：初始化配置（交互式，自动生成 .server.secret + run.sh）
/deploy-init

# 第 2 步：编辑 .server.secret，填入服务器 IP、用户名、SSH 私钥
vim .server.secret

# 第 3 步：一键部署
/deploy
```

#### /socratic-writing — 苏格拉底式文章创作

在 Claude Code 中输入 `/socratic-writing` 触发，用一问一答的方式引导用户把经历和洞见挖成一篇完整文章（默认公众号风格），而不是让用户直接提供素材。

**两种使用方式：**

```bash
# 方式 1：从零开始（空白会话）
/socratic-writing
# → Claude 从"你最想让读者带走什么"开始问，逐步挖出骨架、素材、初稿

# 方式 2：基于本次会话历史作为背景（推荐）
# 先和 Claude 进行了技术讨论、决策分析、踩坑复盘后
/socratic-writing
# → Claude 先扫描本次会话历史，抽取可能的写作方向和原话片段，
#   向用户呈现 2-4 个候选方向，确认后基于真实素材继续追问深挖

# 方式 3：带话题提示
/socratic-writing AI 数据治理
# → Claude 在历史中优先筛选与该话题相关的片段作为候选素材，
#   若历史无相关内容则回退到纯苏格拉底模式围绕该话题提问
```

**核心约束（命令内部已硬约束）：**

- **不虚构**：只使用用户在会话中真实说过的内容，绝不编造场景、情绪、数字
- **保留原话**：引用用户说过的话时逐字保留，不改写
- **可回退**：用户否定历史观察方向时立即切回纯苏格拉底模式
- **只问一个**：任何时候只问一个最重要的问题，问完即等

### templates/ — 部署模板

模板文件部署到 `~/.claude/templates/`，供 `/deploy-init` 命令使用。

#### server.secret.template

服务器连接信息模板，定义了 `.server.secret` 的标准格式（含可选的 `deploy path` 字段）。用户只需替换尖括号内的占位符。

#### run.sh.template

通用服务管理脚本模板，顶部配置区支持自定义：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `APP_ENTRY` | 应用入口文件 | `app.py` |
| `APP_PORT` | 服务端口 | 留空则使用应用默认端口 |
| `ENV_TYPE` | 环境类型 | `conda`（可选 `venv`） |
| `CONDA_ENV` | conda 环境名 | `py312` |
| `VENV_DIR` | venv 目录名 | `venv` |

脚本实现了统一的子命令接口（`start/stop/restart/status/logs`），同时包含：
- conda / venv 双环境自动激活
- PID 文件精确进程管理
- 重复启动保护
- 启动后自动验证
- 日志追加模式（不丢失历史）

## 维护与同步

### 新增配置

```bash
# 在本仓库中添加新的自定义命令，例如新增 /review 命令
vim commands/review.md

# 提交并推送
git add -A && git commit -m "新增 /review 命令" && git push
```

### 同步到其他机器

```bash
cd claude-config
git pull
bash deploy.sh          # Linux / macOS / Git Bash
# 或
powershell deploy.ps1   # Windows PowerShell
```

### 新增配置类型

如需添加新的配置类型（如 hooks、keybindings），步骤：

1. 在仓库中创建对应文件
2. 在 `deploy.sh` 和 `deploy.ps1` 中添加对应的复制逻辑
3. 更新本 README 的配置说明

## 注意事项

- `settings.json` 中的 `skipDangerousModePermissionPrompt` 会跳过风险操作确认，新环境中请根据需要调整
- 部署脚本不会复制 `.credentials.json`、`history.jsonl` 等敏感或会话数据
- 每台机器的 Claude Code 登录凭证需单独通过 `claude login` 获取
