# 新增 /guardrail-init：仓库护栏一键初始化命令

> 2026-07-30 ｜ 规格设计与论证见 voyager 工作区 `voyager/devlog/2026-07-30-1725-guardrail-init-command-spec.md`（及同目录方法论系列文档）

## 做了什么

新增 `commands/guardrail-init.md`：对任意目标仓库执行五阶段护栏初始化——前置检查 → 配置收集（guardrail.config.yaml > 交互 > 探测默认，三模式 ask/defaults/strict）→ 存量探查（并行子代理，产出带 file:line 证据的 CLAUDE.md 四件套草稿 + Top 5–10 条个性化 AI Coding 建议）→ 骨架安装（模板源 = `~/projects/coding/team-quality-config`，按栈裁剪 hooks/skills/lint/CI）→ 平台配置（gh 已认证时自动 secret + branch protection）→ 自检与交付报告。

## 关键设计

- 四条铁律：永不覆盖（增量追加/深合并/snippet+合并指引）、证据强制（无 file:line 不入表，未核实带 ⚠️）、幂等（installed_version + 落盘清单，重跑进补齐模式）、自检闭环（装完真实运行验证）。
- 配置文件既是输入也是产出（回写决策、进 git），支持批量无人值守复制到姊妹仓库。
- 两处必须留人：范式索引人工定稿（防幻觉护栏）、门禁 ratchet 节奏认可。

## 配套

team-quality-config 同步扩充：TS 栈预设（eslint/vitest/CI job snippet + docs/tdd-cc-ts.md）与三份模板（CLAUDE-REPO / guardrail.config / GUARDRAIL-REPORT），见该仓库同日 devlog。

## 待办

- 用一个真实仓库（建议 voyager 三仓之一）走通验收：一次运行骨架落盘+自检绿+报告产出，重跑零重复。
- README 的 commands 列表本次只增了本命令一行；列表整体与 commands/ 目录存在历史性不同步（缺 audit/new-feature/deploy-dry），待单独同步。
