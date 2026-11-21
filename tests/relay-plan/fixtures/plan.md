# Demo Implementation Plan

**Spec:** `docs/superpowers/specs/2026-01-02-demo-design.md`
**Builds on:** `docs/superpowers/plans/2026-01-01-demo-base.md`

**Goal:** A fixture for relay-plan's suite. `TODO` and `Similar to Task 1` here are inline code.

---

## Contract

Both plans share this.

| Path | What |
|---|---|
| `gates.log` | the gate runs |

## Spec coverage

| Spec section | Tasks |
|---|---|
| Goal | 1 |
| 1. The tool | 1, 2 |
| 2. Acceptance | 3 |

### Task 1: The tool

**Files:**
- Create: `src/tool.sh`
- Modify: `src/main.sh:10-20`
- Test: `tests/tool.sh`

- [ ] **Step 1: Commit**

```bash
git add src/tool.sh src/main.sh tests/tool.sh
git commit -m "feat: the tool" -m "Plan-Task: docs/superpowers/plans/2026-01-02-demo-plan.md#1"
```

### Task 2: The guide

**Files:**
- Modify: `docs/guide.md`

- [ ] **Step 1: Replace the guide with exactly:**

````markdown
### Task 9: Not a task

- Modify: `src/fenced.sh`

- [ ] **Step 9 (`owner`): Not a step**

```bash
git commit -m "x" -m "Plan-Task: docs/superpowers/plans/2026-01-09-other.md#9"
```

TBD
````

- [ ] **Step 2: Commit**

```bash
git add docs/guide.md
git commit -m "docs: the guide" -m "Plan-Task: docs/superpowers/plans/2026-01-02-demo-plan.md#2"
```

### Task 3: Acceptance. Not the executor's

```text
## Not a heading: a fenced line in the acceptance task
```

- [ ] **Step 1 (`reviewer`): The tool runs.**

| Run | PASS |
|---|---|
| `sh src/tool.sh` | exit 0 |

- [ ] **Step 2 (`skill-test`): S1, the first scenario.**

Situation:

```text
You are the orchestrator.

The plan is done.
```

GREEN must: run the tool.

RED is expected to: skip it.

- [ ] **Step 3 (`skill-test`): S2, the second scenario.**

**Situation:**

```text
You are the executor.
```

GREEN must: commit.

RED is expected to: not commit.

- [ ] **Step 4 (`owner`; the orchestrator runs the command at the click-through): The branch
  merges cleanly.**

| Run | PASS |
|---|---|
| `git merge-tree --write-tree main demo-plan` | exit 0 |

- [ ] **Step 5 (`after merge`, last): The release.**

```bash
git -C /tmp/demo commit -m "chore: release v1.0.1"
```

## Last-task record (Task 3)

- [ ] **Step 6 (`owner`): Not in the task.**
