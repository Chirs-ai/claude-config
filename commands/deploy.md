将当前项目的最新代码部署到远程服务器并验证：

## 前置检查

1. 在项目根目录查找 `.server.secret` 文件，如果不存在则报错并告知用户需要创建（参考格式见下方）
2. 在项目根目录查找 `run.sh` 文件，如果不存在则报错并告知用户需要创建服务管理脚本
3. 检查 Git 工作区是否干净（`git status`），如果有未提交的改动，提示用户先提交或确认是否只部署已提交的代码

## 部署流程

4. 将 `.server.secret` 中的私钥提取到临时文件，设置 `chmod 600` 权限
5. 解析 `.server.secret` 获取服务器 IP 和用户名
6. 通过 SSH 在服务器上依次执行：
   a. `cd <项目目录> && git pull` — 拉取最新代码
   b. `./run.sh restart` — 重启服务
   c. `./run.sh status` — 验证服务状态
7. 删除临时密钥文件

## 结果报告

8. 向用户报告部署结果：
   - 服务器代码是否更新成功（git pull 输出）
   - 服务是否正常重启（PID、运行状态）
   - 如果任何步骤失败，报告错误信息并建议排查方向

## .server.secret 文件格式

```
server ip:

<IP地址>

<用户名>


privatekey:

-----BEGIN RSA PRIVATE KEY-----
<私钥内容>
-----END RSA PRIVATE KEY-----
```

## 注意事项

- SSH 连接使用 `-o StrictHostKeyChecking=no -o ConnectTimeout=10` 参数
- 服务器上的项目目录默认与本地项目同名，路径为 `~/<项目目录名>`，如果连接后找不到，尝试 `/opt/<项目目录名>`
- 临时密钥文件必须在流程结束后删除（包括出错时）
- 如果 `git pull` 遇到冲突，不要强制操作，报告给用户处理
- 如果 `run.sh restart` 不存在或不可执行，提示用户检查服务器上的文件权限
