为当前项目初始化远程部署配置（`.server.secret` + `run.sh`）：

## 流程

1. 检查项目根目录是否已存在 `.server.secret` 和 `run.sh`，如已存在则提示用户并跳过对应文件

2. **创建 `.server.secret`**（如不存在）：
   - 从 `~/.claude/templates/server.secret.template`（或 `~/projects/claude-config/templates/server.secret.template`）读取模板
   - 如果模板也不存在，使用内置的默认格式
   - 询问用户以下配置项：
     - 服务器 IP 地址
     - SSH 用户名（默认 root）
     - 服务器上的部署路径（默认 `~/<当前项目目录名>`，可自定义如 `/opt/my-app`）
   - 根据用户回答填充模板，写入项目根目录的 `.server.secret`
   - 提示用户还需要手动粘贴 SSH 私钥到文件中

3. **创建 `run.sh`**（如不存在）：
   - 从 `~/.claude/templates/run.sh.template`（或 `~/projects/claude-config/templates/run.sh.template`）读取模板
   - 如果模板也不存在，使用内置的默认脚本
   - 询问用户以下配置项：
     - 应用入口文件名（默认 `app.py`）
     - 服务端口（留空则使用应用默认端口）
     - Python 环境类型（conda / venv）
     - 环境名称（conda 环境名或 venv 目录名）
   - 根据用户回答修改模板中的配置变量，写入项目根目录的 `run.sh`

4. **更新 `.gitignore`**：
   - 检查 `.gitignore` 是否已包含 `.server.secret`
   - 如未包含，追加 `.server.secret` 到 `.gitignore`
   - 同时确保 `app.log` 和 `app.pid` 也在 `.gitignore` 中

5. **报告结果**：
   - 列出创建/跳过的文件
   - 提醒用户编辑 `.server.secret` 粘贴 SSH 私钥
   - 告知用户完成配置后可使用 `/deploy` 一键部署
   - 如果是首次部署（服务器上尚无代码），`/deploy` 会自动在服务器上执行 `git clone`
