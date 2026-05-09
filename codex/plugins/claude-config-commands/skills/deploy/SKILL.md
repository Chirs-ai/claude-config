---
name: "deploy"
description: "Deploy the current project to a remote server using the claude-config deployment workflow. Use when the user asks for deploy, remote deploy, server restart after pull, or the Codex equivalent of the Claude Code /deploy command."
---

# Deploy

Follow the workflow in `../../commands/deploy.md`.

This skill is the Codex replacement for the Claude Code `/deploy` command. Read the referenced command file before acting, then execute its workflow against the current repository. Use `~/.codex/templates/` for Codex-side templates when a template path is needed.
