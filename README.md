# ak-skills

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin —
skills (and, later, agents) by Akahi Troske.

This repository is a Claude Code **marketplace** containing one plugin,
`ak-skills`. Its skills also use the portable Agent Skills format.

## Install

```
/plugin marketplace add AKtroske/ak-skills
/plugin install ak-skills@ak-skills
```

## What's inside

| Type | Name | What it does |
|------|------|--------------|
| Skill | **mental-model** | Builds deep understanding of code through structured teaching + an adaptive quiz. Analyzes a branch diff, PR, directory, or whole repo; teaches with ASCII diagrams + bite-sized notes; then runs a Leitner-system spaced-repetition quiz. |
| Skill | **sticky** | Shows human handoff steps in persistent, independent macOS floating notes with checkboxes and links. |

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

## sticky

Use Sticky when a person needs to leave the agent window to check a browser,
change an account setting, use a device, or complete another concrete handoff.
The agent prepares short steps and shows a floating note that stays visible
across macOS Spaces. Each note has its own ID, window, menu bar pin, links, and
saved checkbox progress, so separate handoffs can stay open at once.

On macOS, the floating helper needs **Python 3.9+**, **Swift with AppKit**
(install Xcode Command Line Tools), and macOS 11 or later. It compiles the Swift
panel on first use and stores its binary under `~/.cache/agent-sticky/` and
note state under `~/.local/state/agent-sticky/`. Neither is part of this repo.
The handoff guidance in [`SKILL.md`](ak-skills/skills/sticky/SKILL.md) works on
other Agent Skills hosts; without the macOS helper, use an available persistent
note surface or give the checklist in chat.

Claude Code discovers Sticky after installing the plugin above. In another
Agent Skills host, install the whole
[`ak-skills/skills/sticky/`](ak-skills/skills/sticky/) directory as a skill so
the scripts remain next to `SKILL.md`. Run the helper by its installed absolute
path, for example:

```bash
python3 /absolute/path/to/sticky/scripts/sticky.py show \
  --id signup-qa \
  --title "Check signup" \
  --step "Open the staging signup page." \
  --step "Confirm the welcome screen appears."
python3 /absolute/path/to/sticky/scripts/sticky.py list
python3 /absolute/path/to/sticky/scripts/sticky.py status --id signup-qa
python3 /absolute/path/to/sticky/scripts/sticky.py clear --id signup-qa
```

Use a different `--id` for each independent floating note. Repeating `show`
updates only that note; `reopen --id signup-qa` restores a closed note with its
checked items. Avoid putting secrets in notes because they stay visible and
persist locally until cleared. See the skill file for structured steps with
links and the full handoff workflow.

## Layout

```
ak-skills/                       # marketplace (this repo)
  .claude-plugin/marketplace.json
  ak-skills/                     # the plugin
    .claude-plugin/plugin.json
    skills/mental-model/SKILL.md
    skills/sticky/
      SKILL.md
      scripts/sticky.py
      scripts/StickyPanel.swift
    agents/                      # (placeholder)
```

## License

[MIT](LICENSE).
