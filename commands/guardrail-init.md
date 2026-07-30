对目标仓库执行护栏自动化初始化：探查存量代码库 → 生成个性化 AI Coding 护栏（CLAUDE.md 四件套草稿 + 个性化建议）→ 安装 team-quality-config 骨架（hooks / skills / lint / CI）→ 配置平台门禁 → 自检并交付报告。

参数：$ARGUMENTS

- `--config <path>`：guardrail.config.yaml 路径（默认取仓库根同名文件）
- `--dry-run`：只探查、只生成变更清单与草稿，不落盘
- `--defaults`：缺配置全用探测默认值（无人值守模式）；缺省为交互模式（缺什么问什么）
- `--template-source <path|git-url>`：模板仓库，默认 `~/projects/coding/team-quality-config`

---

## 铁律（贯穿全程，违反任何一条即停止并报告）

1. **永不覆盖**：目标文件已存在时——CLAUDE.md 纯增量追加章节；`.claude/settings.json` 深合并；lint/CI 配置已有则只输出 snippet + 合并指引，不动原文件。所有落盘动作先列变更清单；非 `--defaults` 模式逐项向用户确认。
2. **证据强制**：范式索引、禁止清单、个性化建议的每一条必须带可验证的 `file:line` 证据；无证据不写入；写入但未经人工核实的条目一律带 `⚠️待确认` 标记。
3. **幂等**：`guardrail.config.yaml` 记录 `installed_version` 与落盘文件清单；重跑时进入"补齐/升级"模式，绝不重复落盘、绝不覆盖用户已定稿的内容。
4. **自检闭环**：安装完成必须实际运行验证（阶段 5）；自检不过不出交付报告，先修或如实报告失败原因。

## 阶段 0：前置检查

1. 确认当前目录在 git 仓库内（否则终止，说明原因）
2. 探测并记录：远端是否 GitHub、`gh auth status` 是否已认证、现有 CI 体系、已有 CLAUDE.md / `.claude/`、已有 lint 与测试配置、是否已装过本护栏（读 `guardrail.config.yaml` 的 `installed_version`）
3. 定位模板源：`--template-source` 指定值或默认路径；不存在 → 询问本地路径或 git clone URL；模板源不可用则终止

## 阶段 1：配置收集（优先级：配置文件 > 交互 > 探测默认）

1. 读 `guardrail.config.yaml`（存在则以它为准，仅补缺项）
2. 需要确定的项：
   - `stacks`：go / ts / python（缺省按 go.mod / package.json / pyproject.toml 探测）
   - `scopes.new_code_dirs`：严格 lint 规则与覆盖率门禁的生效目录（存量不补考的边界）
   - `scopes.generated_dirs`：禁止直接编辑的生成目录（hooks 拦截）
   - `gates.diff_coverage_min` 与 `ratchet` 计划（默认起步 0，只报告不拦）
   - `gates.branch_protection`（分支名与 required checks）
   - `ci`：github / none（none 时必须在报告中警示"缺服务端强制层"）
3. 交互模式下缺什么问什么，一次问清不反复打断；`--defaults` 模式全用探测值
4. 决策回写 `guardrail.config.yaml`（配置即决策记录，进 git）

## 阶段 2：存量探查与个性化建议（并行子代理）

并行派出探索代理，产出六类结论（每条带 file:line 证据）：

1. **技术栈与版本**：语言/框架/关键库精确版本，以及版本陷阱（如 React 17 项目不可用 React 18 API）
2. **目录分层与架构惯例**：分层结构、命名惯例、状态管理方式
3. **范式候选**：新表 / 新页面 / 新接口 / 新状态管理 / 新下发通道等常见任务类型在本仓的"照抄对象"（完整链路的代表实现）
4. **危险区**：生成目录、不可改常量、硬编码约定、跨端契约、同名多义术语
5. **测试与 CI 现状**：框架、测试数量、门禁有无、可复用的测试基建
6. **个性化 AI Coding 建议（Top 5–10 条，宁缺毋滥）**——每条 = 发现（风险或机会）+ 证据 + 建议的护栏动作：
   - 哪些高频重复工作值得做成项目级 skill
   - 哪些目录/文件应由 hooks 拦截编辑
   - 哪些既有约定最容易被 AI 违反（据此在 CLAUDE.md 中加粗强调对应条目）
   - 哪些算法存在多端/多处实现，适用"黄金用例库"机制（单一事实源测试）

产出：按模板源的 `CLAUDE-REPO.template.md` 生成 CLAUDE.md 四件套草稿（版本锁定 / 范式索引 / 禁止清单 / 验证命令）。

## 阶段 3：骨架安装（模板源按栈裁剪，遵守铁律 1）

按 `stacks` 从模板源落盘：

- `.claude/settings.json` + `hooks/`（init / snapshot / fmt / verify，`chmod +x`）
- `.claude/skills/`（feature / fix-bug / remember / handoff / load-progress）+ `.claude/agents/critical-reviewer.md`
- lint 配置：Go → `.golangci.yml`；TS → `eslint.snippet.cjs` + `vitest.config.snippet.ts`；Python → `pyproject.snippet.toml`（snippet 类给出精确合并指引，`new_code_dirs` 代入配置值）
- CI：`.github/workflows/quality-gate.yml` 按 stacks 组装 job（TS job 取 `quality-gate-ts.snippet.yml`；`DIFF_COVER_MIN` 取配置值）
- PR 模板（DoD checklist）、`devlog/` 目录、CLAUDE.md 四件套（新建，或对已有文件纯增量追加）

## 阶段 4：平台配置（能自动则自动）

- `gh` 已认证且有 admin 权限：
  - `gh secret set ANTHROPIC_API_KEY`（向用户索取值，用户可选择跳过）
  - `gh api` 设置 branch protection（required checks = 阶段 3 实际生成的 job 名）
- 否则：在交付报告中输出精确到点击路径的人工操作清单（对应 QUALITY.md 的三步启用）

## 阶段 5：自检与交付

1. 自检（真实运行，不是描述）：lint 跑通（或仅存量豁免范围内的告警）、测试命令可执行、hook 脚本手动触发一次验证行为
2. 按模板源的 `GUARDRAIL-REPORT.template.md` 生成 `GUARDRAIL-REPORT.md`：安装清单（每个文件：新建/追加/snippet 待合并）、自检结果、个性化 AI Coding 建议、待人工事项（范式索引确认清单、平台步骤若未自动完成、ratchet 时间表）、回滚说明（本次落盘文件清单，git 可整体 revert）
3. 向用户汇报摘要，**明确强调两件必须人做的事**：逐条确认范式索引草稿（去除 `⚠️待确认` 标记）、按 ratchet 节奏推进门禁阈值

---

## 流程控制原则

- 每个阶段的检查点不通过，不得进入下一阶段
- 需要用户决策时清晰列出选项与建议值，不自行假设
- 探查结论宁缺毋滥：一条带证据的范式胜过十条泛泛而谈
- 整个流程保持输出简洁，只在关键节点汇报进展
