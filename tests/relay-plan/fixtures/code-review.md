# Review Steps Implementation Plan

**Spec:** `docs/superpowers/specs/2026-01-04-review-design.md`

**Goal:** A fixture for relay-plan's suite: an acceptance task with `code-review` steps.

---

### Task 1: The page

**Files:**
- Modify: `web/page.html`

- [ ] **Step 1: Commit**

```bash
git add web/page.html
git commit -m "feat: the banner" -m "Plan-Task: docs/superpowers/plans/2026-01-04-review-plan.md#1"
```

### Task 2: Acceptance. Not the executor's

- [ ] **Step 1 (`code-review`): Only the planned files.**

| Run | PASS |
|---|---|
| `git diff --name-only main...HEAD` | exactly `web/page.html` |

- [ ] **Step 2 (`reviewer`): The banner shows on the stack.**

- [ ] **Step 3 (`code-review`, a reading): The copy reads as the spec
  says.**

- [ ] **Step 4 (`owner`): The click-through.**

- [ ] **Step 5 (`after merge`, last): The release.**
