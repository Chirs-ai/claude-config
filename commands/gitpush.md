执行 Git 提交并推送流程：

1. 检查当前 git 状态（使用 `git status`）
2. 查看所有更改（使用 `git diff` 和 `git diff --staged`）
3. 查看最近的 commit 历史以了解 commit message 风格（使用 `git log --oneline -5`）
4. 将所有更改添加到暂存区（使用 `git add -A`）
5. 根据更改内容生成简洁、有意义的 commit message（中文或英文取决于项目风格）
   - 不要添加 Co-Authored-By
   - commit message 应简明扼要地描述更改的内容和目的
6. 创建 commit（使用 `git commit -m "message"`）
7. 推送到远程仓库（使用 `git push`）

如果遇到以下情况请告知用户：
- 没有任何更改需要提交
- 推送时发生冲突
- 远程仓库需要先 pull
- 其他 git 错误

注意：
- 如果没有配置远程仓库，提示用户先配置
- 如果是新分支，使用 `git push -u origin <branch>` 设置上游
