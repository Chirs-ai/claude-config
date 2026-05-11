---
name: "gitpush"
description: "Commit and push current Git changes using the claude-config workflow. Use when the user asks for $gitpush, gitpush, 提交, commit, commit and push, or one-shot git publish in Codex."
---

# Gitpush

Follow the workflow in `../../commands/gitpush.md`.

Codex skill for `$gitpush`. Across all Codex projects, plain requests such as "提交" or "commit" mean commit and push unless the user explicitly says local-only or no push. Read the referenced command file before acting, then inspect status, diffs, staged changes, and recent commit style before staging, committing, and pushing. Do not add `Co-Authored-By`.
