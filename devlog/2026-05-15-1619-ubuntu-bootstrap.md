# Ubuntu 一体化安装入口

## 需求

在全新 Ubuntu 环境中，一键安装并配置 Claude Code CLI 和 Codex CLI。不能假定系统已有 Node.js/npm；但只有操作系统是 Ubuntu 时才执行软件安装，其他平台保持配置同步行为。

## 方案

- 新增 `bootstrap.sh` 作为上层入口。
- 新增 `install-ubuntu.sh` 作为裸 Ubuntu 入口，负责安装最小拉取依赖、克隆或更新仓库，再调用 `bootstrap.sh`。
- `bootstrap.sh` 判断 `/etc/os-release` 的 `ID=ubuntu`，并排除 WSL。
- 原生 Ubuntu 执行：
  - apt 安装 `curl`、`git`、`jq`、`bc`、`gnupg` 等基础依赖。
  - 通过 Anthropic 官方 apt 仓库安装 `claude-code`，并校验签名 key 指纹。
  - 通过 NodeSource 安装 Node.js 22.x/npm。
  - 配置用户级 npm global prefix，避免默认使用 `sudo npm install -g`。
  - 安装/升级 `@openai/codex` 和 `ccstatusline`。
  - 验证 `node`、`npm`、`claude`、`codex` 可执行。
- 所有平台最后都调用现有 `deploy.sh` 同步 `.claude` / `.codex` 配置。

## 影响

- `deploy.sh` 不改变职责，仍是跨平台配置同步入口。
- 裸 Ubuntu 不再需要预先安装 Git；README 提供 `apt install curl` 后远程执行 `install-ubuntu.sh` 的一体化命令。
- WSL 不做软件安装，避免 CLI 装在 Linux 侧但配置写入 Windows 侧的路径错配。
- 用户凭证仍需在目标机器上交互式登录，不纳入同步范围。

## 验证计划

- `bash -n bootstrap.sh`
- `bash -n install-ubuntu.sh`
- `bash -n deploy.sh`
- 检查 README 是否明确区分全新 Ubuntu 和配置同步路径。
