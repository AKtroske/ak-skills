---
name: sticky
description: Put concrete actions the user must perform outside the agent's current window into a persistent on-screen checklist. Use for human browser QA, account or website changes, device steps, and other handoffs that require switching apps or windows.
---

# Sticky

When work reaches actions that the user must perform in another app, browser window, device, or physical setting, put those actions in a checklist that remains visible while they switch context. The included floating helper requires macOS, Python 3, and Apple's Swift compiler. The handoff instructions work in other agent hosts. The skill is for actual handoffs, not routine progress updates or actions the agent can complete itself.

## Prepare the handoff

- Complete the work the agent can do first. Identify the exact point where the user's action is required.
- Do one quick editing pass before showing the note. Turn each step into a short verb-first action (for example, "Open Clerk DEV" or "Check Backup codes"). Put the click path, value to check, or expected result in an optional one-line detail. Add a direct link to the page or artifact when its URL is known. Do not invent links.
- Keep distinct environments, order dependencies, required values, and approval gates explicit. Split a compound instruction when the user must complete or report one action before the next. Remove conversational filler, not operational detail.
- Keep the checklist small enough to scan while switching windows. Put longer explanations in chat or a linked guide; the sticky should carry the next action and the detail needed to perform it.
- Never put passwords, one-time codes, recovery phrases, private tokens, or other secrets in the sticky. The note is visible over other apps and saved in a local state file until cleared.
- If a step needs a decision or approval, make that decision explicit in chat. A sticky is a reminder, not authorization.

## Show and maintain the sticky

Find this skill's directory and run its helper using an absolute path. On macOS:

```bash
python3 /absolute/path/to/sticky/scripts/sticky.py show \
  --id signup-qa \
  --title "Check the signup flow" \
  --step "Open the staging signup page in your browser." \
  --step "Complete signup and confirm the welcome screen appears." \
  --step "Return here with the result or any error text."
```

For guided steps with links, pass structured JSON through stdin or a file:

```bash
python3 /absolute/path/to/sticky/scripts/sticky.py show --id signup-qa --json - <<'JSON'
{"title":"Check signup","steps":[{"text":"Open staging signup","detail":"Complete the form; confirm the welcome screen appears.","url":"https://example.com/signup","link_label":"Open signup"}]}
JSON
```

Replace the example URL with the real destination. Each step needs `text`; `detail`, `url`, and `link_label` are optional. `url` accepts `https:`, `http:`, or `file:` links, so a local guide can be opened from the sticky too.

The helper opens a floating checklist across macOS Spaces without taking keyboard focus. The user can tick items, open links, and drag the window. Use a stable `--id` for each independent handoff. Multiple IDs open separate, slightly offset panels; omitting `--id` uses the original `default` note. Run `python3 .../sticky.py list` to see saved notes before updating one. Re-running `show` replaces only the note with that ID.

Closing a panel hides that note and keeps its checked items; its menu bar pin's **Show** item restores it. The agent can also run `python3 .../sticky.py reopen --id signup-qa` when the user asks to reopen it. Use `status --id signup-qa` to read checkbox state and `clear --id signup-qa` after that handoff is finished; clearing deletes only that note and removes its menu bar pin. Never clear an unrelated note.

If the helper cannot run, choose an available note surface that genuinely stays visible across the user's target windows. If there is no such surface, provide the concise checklist in chat and state that it is not pinned. Do not claim an ordinary chat message is a floating sticky.

Keep the handoff in chat as well: say what needs user action, where the sticky is, and what result the user should report back. Resume the original task when the user returns.
