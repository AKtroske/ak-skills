---
name: mental-model
description: "Use when you want to deeply understand code: a feature you're reviewing, a branch or PR you (or an agent) just built, or an existing implementation you're revisiting to onboard or refresh. For building a mental model of architecture, data flows, module interfaces, and how changes ripple through a system. Not for syntax lookups or debugging a specific error."
---

# Mental Model Builder

Build deep understanding of code through structured teaching and adaptive quizzing. The goal is not syntax — it's understanding **how data flows**, **how modules talk to each other**, and **how changes interact with the rest of the system**.

## When to Use

- After making or reviewing changes on a branch — understand how they fit into the system
- When onboarding to a new area of the codebase
- When reviewing someone else's PR or branch
- When you want to understand a directory or the full repo architecture

## When NOT to Use

- For syntax reference or API lookups — use docs
- For debugging a specific error — use systematic-debugging

## Scope Detection

This skill serves two primary use cases:
- **(A) Understanding changes** — a feature under review, or one you/an agent just built.
- **(B) Revisiting existing code** — onboarding to, or refreshing your memory of, an implementation that already exists.

Map the user's argument to a scope:

| User says | Scope | Use case |
|---|---|---|
| *(nothing / just invokes the skill)* | Diff of the current branch vs the default branch + staged/unstaged changes | A |
| A PR number/URL or a commit range (e.g. `abc123..def456`) | The diff for that PR or range | A |
| A directory or file path (e.g., `backend/internal/`) | All code in that tree | B |
| `repo` | Full repository architecture | B |

**Getting the diff for each change-based (A) scope:**
- **No argument:** `git diff <default>...HEAD` for committed work, **plus** the working tree — `git diff` (unstaged) and `git diff --staged` (staged).
- **Commit range** (`a..b` / `a...b`): `git diff <range>`.
- **PR number/URL:** `gh pr diff <number>`. A PR diffs against *its own base branch*, which may not be your local default — do not assume it.

**Detect the default branch — never hardcode `main`.** Resolve it in order, stopping at the first that works:
1. `git symbolic-ref --short refs/remotes/origin/HEAD` (e.g. `origin/main` → `main`)
2. the current branch's upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{u}`
3. whichever of `origin/main` / `origin/master` / local `main` / `master` exists

If none resolve (e.g. a `develop`-trunk repo with `origin/HEAD` unset), **ask the user which branch to diff against** — do not guess `main`.

When scope is change-based (use case A), **always** include how the changes interact with the rest of the system — never analyze changes in isolation.

## Process Flow

```
Determine scope
      |
      v
Read & analyze code
      |
      v
Build notes internally (do NOT dump them all upfront)
      |
      v
TEACH phase: ASCII diagram + data flows + key insight
      |
      v
User ready for quiz?
  yes |          | more questions
      v          v
   QUIZ       Answer & re-ask
Round 1: Box 1, all question types interleaved
Round 2: Box 2 revisits, multiple choice only
Round 3: Final confirmation, short quick answers
      |
      v
Summary & offer to save
```

---

## Phase 1: Analyze

Read the code in scope. For each piece, identify:

1. **Architecture layers** — What are the main components/modules? How are they organized?
2. **Data flows** — How does data enter, transform, and exit? Trace key paths end-to-end.
3. **Internal interfaces** — How do modules communicate? Function calls, channels, events, gRPC, message queues?
4. **External interfaces** — What external systems are involved? APIs consumed or exposed, databases, third-party services?
5. **Key patterns** — What design patterns, conventions, or idioms are used? Why?

For branch-scoped analysis, also identify:
- **What changed** — the direct modifications
- **What it touches** — the modules, interfaces, and flows affected by the change
- **Why it matters** — the system-level impact of the change

Build **8–15 bite-sized notes** from the analysis internally. Assign each a stable number (`#1`…`#N`) — you will track its Leitner box by that number throughout the quiz. Each note should:
- Cover exactly one concept, flow, or interface
- Be 2–4 sentences
- Explain the "why" not just the "what"
- Reference specific files/functions when helpful

Generate **1–3 diagrams** using **ASCII art** (not dot/graphviz/mermaid notation — those do not render in the terminal).

**Self-check before sending any diagram:** if it starts with `digraph`, `graph`, `flowchart`, or a ` ```dot ` / ` ```mermaid ` fence, STOP — that is diagram *source code*, not a rendered picture, and the user will see raw text. Redraw it with ASCII box-and-arrow characters (`|`, `-`, `+`, `>`, `v`).

---

## Phase 2: Teach

**Do not dump all notes upfront.** The upfront teaching material is brief and scannable — diagram + data flows + key insight only. The bite-sized notes are held back and first surface *during the quiz*, where they are re-presented after every answer (see Phase 3). This makes each note land as retrieval practice, not passive reading.

### Structure

1. **Architecture Overview** — Present an ASCII diagram showing how the system/changes are structured. Walk through it briefly.

Example ASCII style:
```
  Browser
     |
  [backend] --gRPC--> [agent-service]
     |
  [postgres]
```

2. **Data Flow Walkthrough** — Trace 1–2 key data flows end-to-end as numbered sequences showing each hop.

3. **Key Insight** — One "aha" sentence that ties the pieces together — the thing that, once understood, makes the rest click.

After presenting, ask: **"Ready for the quiz? Or do you have questions about any of the material?"**

If the user has questions, answer them, then re-ask. Do not proceed to the quiz until the user confirms.

---

## Phase 3: Quiz

An adaptive quiz using a simplified **Leitner system** for within-session spaced repetition.

### Leitner Boxes

All notes start in **Box 1**. Three boxes total:

| Box | Phase | Meaning |
|---|---|---|
| Box 1 | Round 1 (all question types) | Not yet learned — needs practice |
| Box 2 | Round 2 (multiple choice only) | Getting it — needs reinforcement |
| Box 3 | Round 3 (rapid-fire confirmation) | Learned — confirm once |

**Promotion:** Correct answer → note moves to the next box.
**Demotion:** Wrong answer → note returns to Box 1. Re-present the note before continuing.

### Question Types by Round

Rounds are phase-gated: **do not advance to the next round until Box 1 (for Round 2) or Box 2 (for Round 3) is completely empty.** If a wrong answer demotes a note back into the earlier box, stay in the current round and re-ask it before moving on.

**Round 1 — while Box 1 has notes: All three types, interleaved**

Continue Round 1 until Box 1 is empty. Do not start Round 2 until every note has been promoted out of Box 1.

Do not use the same type consecutively. Interleave:

- **Multiple Choice (Recognition):** 4 options, test facts/components/relationships.
- **Trace the Flow (Application):** User describes what happens end-to-end when an event occurs.
- **Why Questions (Elaborative Interrogation):** User explains why a design decision was made.

**Round 2 — while Box 2 has notes: Multiple choice only**

Begin Round 2 only when Box 1 is empty. Continue until Box 2 is empty. All questions use multiple choice — this is a recognition pass; the user has already explained these concepts once. If a wrong answer demotes a note back to Box 1, ask it again immediately using any Round 1 question type, then continue Round 2 with remaining Box 2 notes.

**Round 3 — while Box 3 has unconfirmed notes: Short quick answers**

Begin Round 3 only when Box 2 is empty. One-sentence or one-word answers only. Move fast. Examples:
- "In one sentence: what is X and why does it exist?"
- "Complete this sentence: ___"
- "Name the two things Y checks."

### Quiz Rules

- **One question per message.** Wait for the user's answer before proceeding.
- **After each answer**, respond with:
  - Whether they were correct (and why, briefly)
  - **Always** re-present the relevant note — correct or wrong. Correct answers may be guesses; the note reinforces the concept either way.
  - If wrong: keep note in Box 1
  - The current box state, printed **every turn** so it survives long sessions: a per-note ledger you carry verbatim, e.g. `#1→B3 #2→B1 #3→B2 …`, followed by the rollup `[Box 1: 3 | Box 2: 2 | Box 3: 4]`. Recompute the rollup from the ledger each turn — do not track counts from memory, or they will drift.
- **Interleave topics** — don't ask all questions about the same module back-to-back.
- **If the user gets a note wrong twice**, rephrase the question — same concept, different angle.

### Completion

The quiz ends when all notes are in Box 3 and confirmed. Present:

1. **Score summary** — how many notes were learned on first try vs. needed repetition
2. **Hardest concepts** — which notes took the most attempts
3. **ASCII architecture diagram** — re-present as a reference

Then offer: **"Want me to save these notes to a file for future reference?"**

If yes, save a markdown file with the ASCII diagrams, the numbered notes, and which concepts were hardest. Default to `docs/mental-model/<date>-<topic>.md` (get `<date>` from `date +%F`). If `docs/` does not exist or is not writable — or you are not in a repo — ask the user where to save instead of assuming the path.

---

## Key Principles

- **Teach before testing** — exposure must precede retrieval practice
- **Notes appear after every answer** — always re-present the note after each question, correct or wrong; correct answers may be guesses and the note reinforces the concept either way. Never front-load all notes upfront.
- **ASCII only for diagrams** — dot/graphviz notation does not render in the terminal
- **One question at a time** — don't overwhelm; wait for response
- **Wrong answers are learning events** — always re-present the note, never just say "wrong"
- **Interleave** — mix topics and question types for stronger retention
- **Round structure enforces progression** — Round 1 varies, Round 2 multiple choice, Round 3 rapid-fire
- **Focus on flows, not syntax** — architecture, interfaces, data movement
- **Branch changes in context** — never analyze changes in isolation; show how they connect to the rest of the system
