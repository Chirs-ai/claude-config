将当前项目的最新代码部署到远程服务器并验证：

## 前置检查

1. 在项目根目录查找 `.server.secret` 文件，如果不存在则报错并告知用户可通过 `/deploy-init` 创建
2. 在项目根目录查找 `run.sh` 文件，如果不存在则报错并告知用户可通过 `/deploy-init` 创建
3. 检查 Git 工作区是否干净（`git status`），如果有未提交的改动，提示用户先提交或确认是否只部署已提交的代码

## 解析 .server.secret

4. 将 `.server.secret` 中的私钥部分（从 `-----BEGIN` 到 `-----END` 行）提取到临时文件，设置 `chmod 600` 权限
5. 解析以下字段：
   - **server ip:** 后的第一个非空行 → 服务器 IP
   - IP 下一个非空行 → SSH 用户名
   - **deploy path:** 后的第一个非空行 → 部署路径（可选）
   - 如果 `deploy path:` 不存在或值为空或包含尖括号（`<`），则默认使用 `~/<本地项目目录名>`

## 部署流程

6. 通过 SSH 连接服务器，检查部署目录是否存在：

   **情况 A：目录已存在** → 更新部署
   a. `cd <部署路径> && git pull` — 拉取最新代码
   b. `./run.sh restart` — 重启服务
   c. `./run.sh status` — 验证服务状态

   **情况 B：目录不存在** → 首次部署
   a. 从本地项目获取 git remote URL（`git remote get-url origin`）
   b. 在服务器上执行 `git clone <remote-url> <部署路径>` — 克隆代码
   c. 提示用户：首次部署需要在服务器上完成环境配置（安装依赖、编辑配置文件等），
      可参考项目的部署文档（如 DEPLOY.md），本次不自动执行 `run.sh restart`
   d. 如果项目有 `run.sh`，告知用户配置完成后可在服务器上执行 `./run.sh start` 启动服务，
      或者再次运行 `/deploy` 进行自动重启

7. 删除临时密钥文件（无论成功或失败都必须执行）

## 结果报告

8. 向用户报告部署结果：
   - 部署类型（更新 / 首次克隆）
   - 服务器代码是否更新成功（git pull / clone 输出）
   - 服务是否正常重启（PID、运行状态）— 仅更新部署时
   - 如果任何步骤失败，报告错误信息并建议排查方向

## .server.secret 文件格式

```
server ip:

<IP地址>

<用户名>


deploy path:

<可选：服务器上的部署路径，如 /opt/my-app>


privatekey:

-----BEGIN RSA PRIVATE KEY-----
<私钥内容>
-----END RSA PRIVATE KEY-----
```

**字段说明：**

| 字段 | 必填 | 说明 |
|------|------|------|
| server ip | 是 | IP 地址或域名 |
| 用户名 | 是 | SSH 登录用户名（紧跟在 IP 下方） |
| deploy path | 否 | 服务器上的项目路径，默认 `~/<本地项目目录名>` |
| privatekey | 是 | SSH 私钥（RSA / ED25519 等） |

## 注意事项

- SSH 连接使用 `-o StrictHostKeyChecking=no -o ConnectTimeout=10` 参数
- 临时密钥文件必须在流程结束后删除（包括出错时）
- 如果 `git pull` 遇到冲突，不要强制操作，报告给用户处理
- 如果 `run.sh restart` 不存在或不可执行，提示用户检查服务器上的文件权限
- 首次克隆时不自动重启，因为服务器可能还没有完成环境配置（conda/venv、依赖安装、配置文件等）
- 向后兼容：没有 `deploy path:` 字段的旧格式 `.server.secret` 仍然正常工作
