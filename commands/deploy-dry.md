试运行部署：使用免费模型部署到远程服务器，用于功能验证而非 AI 质量测试。

## 与正式部署的区别

本命令在执行标准部署流程的基础上，额外将服务器上 `.env` 中的 `DEFAULT_MODEL` 切换为免费模型，以节省 token 费用。

免费模型：`stepfun/step-3.5-flash:free`

## 部署流程

执行与 `/deploy` 完全相同的前置检查、解析 `.server.secret`、部署流程（git pull + run.sh restart），但在 `git pull` 之后、`run.sh restart` 之前，增加一步：

### 切换模型

通过 SSH 在服务器上执行：

```bash
sed -i 's/^DEFAULT_MODEL=.*/DEFAULT_MODEL=stepfun\/step-3.5-flash:free/' <部署路径>/.env
```

执行后打印切换结果，确认 `.env` 中的 `DEFAULT_MODEL` 已更新。

## 完成后提醒

部署成功后，提醒用户：
- 当前服务器使用的是**免费模型**（试运行模式）
- 功能验证完成后，使用 `/deploy` 正式部署即可自动切回生产模型
