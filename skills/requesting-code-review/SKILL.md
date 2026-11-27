---
name: requesting-code-review
description: Use for a branch's code review before it merges (in the relay, once per branch and last, run by orchestrating's reviewing.md), or ad hoc when stuck, before a refactor, or after a complex bug fix
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they merge. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** one review of the whole branch, last, against its plan and its spec.

## When to Request Review

**Mandatory:**
- Once per branch, after its acceptance check and the fixes it led to, before the merge

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base main <branch>)
# a branch stacked on another plan's branch that has not merged: BASE_SHA=$(git rev-parse <base branch>)
HEAD_SHA=$(git rev-parse <branch>)
```

**2. Dispatch code reviewer subagent:**

A general-purpose agent, with `model: sonnet` in Claude Code (in OpenCode, the `general` subagent), given the template at `code-reviewer.md` with its placeholders filled in.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - The plan's path, or what it should do
- `{SPEC}` - The spec's path
- `{PLAN_STEPS}` - The plan's `code-review` steps, each id with the command that prints it (`relay-plan step <plan> <id>`), or "none" (ad hoc, or a plan without them)
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{RUN_DIR}` - The plan's run folder, where the review goes ("none" outside the relay)
- `{INITIATIVE}` - The plan's initiative, for the cards the reviewer files ("none" without Quartz)

**3. Act on feedback:**

In the relay, the reviewer writes its full review to the run folder's `code-review.md` and hands back a short summary.
- **Critical:** fixed before the merge. In the relay, the executor fixes it, after the orchestrator checks it against the code with `hyper-relay:receiving-code-review`.
- **A plan step's FAIL:** fixed before the merge, as a Critical is, once the orchestrator has checked it against the code. Never a card.
- **Important and Minor:** in the relay, the reviewer files each as a proposed card, labelled `proposed`, which the owner prunes on the board; outside it, noted in the review. They do not block the merge.
- Push back if the reviewer is wrong (with reasoning).

## Example

```
[Acceptance passed on the branch index-repair; the fixes it led to are committed]

BASE_SHA=$(git merge-base main index-repair)
HEAD_SHA=$(git rev-parse index-repair)

[Dispatch code reviewer subagent, model: sonnet]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: docs/superpowers/plans/2026-11-18-index-repair.md
  SPEC: docs/superpowers/specs/2026-11-18-index-repair-design.md
  PLAN_STEPS: none
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  RUN_DIR: <main checkout>/.hyper-relay/runs/index-repair/
  INITIATIVE: v1

[Subagent writes code-review.md in the run folder, files the Important and Minor issues as proposed cards, and returns]:
  Ready to merge: With fixes. Critical 1, Important 1, Minor 1.
  Critical: repairIndex() deletes entries it cannot parse (data loss), src/repair.ts:88
  Cards: 3f2a9c10, 8b7e6d54
  Review: <main checkout>/.hyper-relay/runs/index-repair/code-review.md

You: [Read the Critical issue in code-review.md and check it against the code: it is real, so the executor fixes it]
[Important and Minor: already on the board as proposed cards]
```

## Integration with Workflows

**In the relay:**
- `hyper-relay:orchestrating`'s `reviewing.md` runs it once per branch, last: after the acceptance check and its fixes, so it reads the final diff
- Critical goes to the executor; the reviewer files Important and Minor as proposed cards, labelled `proposed`

**Ad hoc:**
- Before a merge outside the relay
- When stuck, before refactoring, after a complex bug fix

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Merge with an unfixed Critical issue
- Drop a finding without recording it
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md
