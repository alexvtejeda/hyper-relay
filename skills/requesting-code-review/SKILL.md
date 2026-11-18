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
HEAD_SHA=$(git rev-parse <branch>)
```

**2. Dispatch code reviewer subagent:**

A general-purpose agent, with `model: sonnet` in Claude Code (in OpenCode, the `general` subagent), given the template at `code-reviewer.md` with its placeholders filled in.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - The plan's path, or what it should do
- `{SPEC}` - The spec's path
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- **Critical:** fixed before the merge. In the relay, the executor fixes it, after the orchestrator checks it against the code with `hyper-relay:receiving-code-review`.
- **Important and Minor:** proposed cards for the owner to keep or drop, or noted in the report. They do not block the merge.
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
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Critical: repairIndex() deletes entries it cannot parse (data loss)
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: With fixes

You: [Check the Critical issue against the code: it is real, so the executor fixes it]
[Important and Minor: proposed cards]
```

## Integration with Workflows

**In the relay:**
- `hyper-relay:orchestrating`'s `reviewing.md` runs it once per branch, last: after the acceptance check and its fixes, so it reads the final diff
- Critical goes to the executor; Important and Minor become proposed cards

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
