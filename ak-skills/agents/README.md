# Agents

Custom subagent types shipped by this plugin. Each agent is a single Markdown
file with YAML frontmatter; Claude Code's `Agent`/`Task` tool can dispatch it by
the `name` below.

This directory is currently a placeholder — no agents are shipped yet.

## Format

```markdown
---
name: my-agent
description: Use when ... (when the main thread should dispatch this agent)
tools: Read, Grep, Glob   # optional allowlist; omit to inherit all tools
model: sonnet             # optional model override
---

System prompt for the agent. It runs in an isolated context and returns only
its final message to the caller, so tell it to return structured, self-contained
results.
```

## Skills vs agents (when to add which)

- **Skill** (`../skills/`): runs in the **main conversation**, sees full history,
  the model loads it contextually. Use for techniques/workflows.
- **Agent** (here): runs in an **isolated context**, reports back a summary.
  Use for fan-out, read-only exploration, or work that would bloat the main
  thread. Skills may *dispatch* agents.
