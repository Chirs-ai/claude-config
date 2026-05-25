# Plan Devlog Build Command

时间：2026-05-25 16:57

## 背景

用户希望把常用 SOP “结合上下文总结详细方案，写入 devlog 文档，自评方案是否 OK，没问题后开始实施” 抽象为命令，并同步加入 `claude-config`，同时兼容 Claude Code 和 Codex。

## 方案

新增命令名：`plan-devlog-build`。

Claude Code 侧：

- 新增 `commands/plan-devlog-build.md`
- 部署后通过 `/plan-devlog-build` 触发

Codex 侧：

- 新增 `codex/prompts/plan-devlog-build.md`
- 新增 `codex/plugins/claude-config-commands/commands/plan-devlog-build.md`
- 新增 `codex/plugins/claude-config-commands/skills/plan-devlog-build/SKILL.md`
- 新增 `codex/plugins/claude-config-commands/skills/plan-devlog-build/agents/openai.yaml`
- 部署后通过 `$plan-devlog-build` 触发

文档侧：

- 更新 README 的命令列表、Codex 示例和命令说明
- 更新 Codex 插件描述，让 marketplace 文案覆盖该 workflow

## 自评

现有 `deploy.sh` 和 `deploy.ps1` 都使用通配符同步 `commands/*.md`、`codex/prompts/*.md`、插件 `commands/*.md` 和 `skills/*`，因此新增文件即可被部署脚本发现，不需要修改部署脚本。

风险点：

- Claude Code 侧现有 `commands/` 文件通常不带 YAML frontmatter，因此保持同风格，只写命令正文。
- Codex 侧现有 prompt/plugin command 文件带 YAML frontmatter，因此 Codex 版本保留 `description` 和 `argument-hint`。
- Skill 使用 `../../commands/plan-devlog-build.md` 引用 workflow 正文，与现有 skills 相同。

## 验证计划

- 使用 skill 校验脚本检查新 Codex skill frontmatter
- 使用 JSON parser 校验插件 manifest
- 检查新增文件是否被 `find` 枚举到预期位置
- 查看 `git diff --check`，确认没有空白错误

## 实施结果

已完成新增命令、Codex prompt、Codex plugin command、Codex skill 入口和 README/plugin manifest 更新。

验证结果：

- `quick_validate.py codex/plugins/claude-config-commands/skills/plan-devlog-build`：通过
- `python3 -m json.tool codex/plugins/claude-config-commands/.codex-plugin/plugin.json`：通过
- `python3 -m json.tool codex/.agents/plugins/marketplace.json`：通过
- `git diff --check`：通过
