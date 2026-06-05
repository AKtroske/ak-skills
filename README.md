# ak-skills

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin —
skills (and, later, agents) by Akahi Troske.

This repository is a Claude Code **marketplace** containing one plugin,
`ak-skills`.

## Install

```
/plugin marketplace add AKtroske/ak-skills
/plugin install ak-skills@ak-skills
```

## What's inside

| Type | Name | What it does |
|------|------|--------------|
| Skill | **mental-model** | Builds deep understanding of code through structured teaching + an adaptive quiz. Analyzes a branch diff, PR, directory, or whole repo; teaches with ASCII diagrams + bite-sized notes; then runs a Leitner-system spaced-repetition quiz. |

Agents may be added under [`ak-skills/agents/`](ak-skills/agents/) later — the
slot is scaffolded.

## mental-model

A teaching tool: the goal isn't to do work for you, it's to make *you*
understand a slice of code — how data flows, how modules talk, and how a change
ripples through the system.

**Use it when:**
- Reviewing a feature you (or an agent) just built
- Revisiting an existing implementation to onboard or refresh

**Invoke:**

```
/mental-model                       # current branch's changes vs the default branch
/mental-model <pr-url|commit-range> # a specific PR or range
/mental-model backend/internal/...  # an existing directory or file
/mental-model repo                  # whole-repository architecture
```

It teaches first (ASCII architecture diagram, data-flow walkthrough, one key
insight), then quizzes you with a three-round Leitner box system — promoting
notes you know and re-teaching the ones you miss — and finally offers to save
your notes for later.

## Layout

```
ak-skills/                       # marketplace (this repo)
  .claude-plugin/marketplace.json
  ak-skills/                     # the plugin
    .claude-plugin/plugin.json
    skills/mental-model/SKILL.md
    agents/                      # (placeholder)
```

## License

[MIT](LICENSE).
