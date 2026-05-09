---
name: "deploy-init"
description: "Initialize claude-config deployment files for a project. Use when the user asks for deploy-init, deployment setup, create .server.secret, create run.sh, or the Codex equivalent of the Claude Code /deploy-init command."
---

# Deploy Init

Follow the workflow in `../../commands/deploy-init.md`.

This skill is the Codex replacement for the Claude Code `/deploy-init` command. Read the referenced command file before acting, then execute its workflow against the current repository. Use `~/.codex/templates/` for Codex-side templates when a template path is needed.
