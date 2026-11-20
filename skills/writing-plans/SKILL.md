---
name: writing-plans
description: Use when dispatched as a planner to write an implementation plan from an approved spec (the planner agents preload it). An orchestrator with an approved spec uses orchestrating instead, which dispatches the planner.
---

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. They write idiomatic code in the project's language once they know the exact interface and the exact test, and they make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** A plan names neither where it runs nor a path to run it in: no worktree path, no `cd` prefix. The orchestrator sets up a branch or a worktree at the handoff (`hyper-relay:orchestrating`'s `dispatching.md`), and the dispatch prompt tells the executor where it is.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## The spec's plan count

Before writing, compare the number of plans you intend to write with the spec's `**Plans:** <n>` header line. A spec without the line means 1. If they differ, stop before writing any plan and report the mismatch to the orchestrator: the number you would write, and why. It asks the owner, updates the spec's `**Plans:**` line itself (`hyper-relay:orchestrating`'s `planning.md`), and dispatches you again. Never edit the spec: you write plans only.

## Facts about outside systems

The spec's `## How it works` section holds the facts about outside systems that its design rests on (a file format, a CLI, an API, docs, data on the machine), each with its source and the date it was checked. They are settled: build on them. Do not work them out again or re-check them, except the facts the section flags for re-check: check each of those with WebFetch or WebSearch, cite its URL and the date in the plan, quote only what decides something, and list a difference as a deviation, never a silent design change. A spec written before this rule may keep such facts under another heading, such as External facts: they are settled the same way, and those it asks you to re-check count as flagged.

Reading the repo's own code is your job, as always.

When the plan needs a fact about an outside system that the spec does not settle, read at most one file or one page to confirm a detail. Do not investigate: no series of searches, no digging through data, no working out a format from samples. Write the plan on a stated assumption, list it in the plan's table of spec ambiguities and deviations, marked **Assumption**, and put it in your report among what the owner must decide. The owner accepts it, corrects it, or has it researched and sends you back with the facts (`hyper-relay:orchestrating`'s `planning.md`).

Your report names the facts you re-checked (those the spec flagged) and any differences, and the assumptions you made where the spec was silent.

## Stacked plans

When the spec's list of plans says your plan builds on another, your plan's header carries `**Builds on:** <base plan path>`, beside its `**Spec:**` line, above its first `---`. The orchestrator dispatches you once the base plan is committed: read it, and plan against the files as the base plan leaves them (its tasks' files, signatures and text), not as `main` has them. A plan builds on exactly one plan. Its branch is cut from the base's branch (`hyper-relay:orchestrating`'s `parallel.md`).

## Sent back to renumber

When the orchestrator sends your plan back because another plan in flight creates files with the same leading number in the same folder (`000097_*` migrations, say), renumber yours above the highest number its prompt names, everywhere the plan names them (paths, code, commands), and commit the plan again.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and its own commit, with its `Plan-Task:` trailer. Fold setup, configuration, scaffolding and documentation into the task whose deliverable needs them. Split only where one task's result can be checked without its neighbour's. Each task ends with something testable on its own.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: hyper-relay:executing-plans (the executor preloads it). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Execution notes

A plan's **Execution notes** carry what is particular to it: a command not to run, a file's quirk, a suite that is the contract, the suites its full gates run. They also carry the spec's project-wide values (version floors, dependency limits, naming and copy rules, exact values), copied verbatim, one line each. They do not repeat the executor's standing rules, which `hyper-relay:executing-plans` holds: where it works, how it commits and with which trailers, its never list, and running each task's own checks with the full gates once at the end.

## Review Focus

After its header and before its first task, the plan carries a **Review Focus** section: up to five input classes or failure modes that the spec implies but no task's tests exercise, the ones most likely to bite a person using the software, most likely first. Each is one line, naming the input or condition and the behaviour a reasonable person would expect. The spec is a vision document: its silence on an input is not permission for that input to break the program. Each line's test goes into the test step of the task that owns the code, with its name and assertions, beside the spec's own cases: a Review Focus line that no test step asserts is a gap. An empty section means you checked and found none, not that you skipped the check.

## No Quartz steps in a plan

A plan carries no `quartz link-branch` step and no `quartz review` step: the orchestrator runs both, at dispatch and after verifying the executor's report (`hyper-relay:orchestrating`'s `dispatching.md`).

## Spec coverage and the acceptance task

- After the header, a **Spec coverage** table maps each `## ` section of the spec to the task numbers that implement it. With sibling plans, each plan has a **Contract** section, identical in each.
- The plan ends with its acceptance task. Each of its steps names who runs it: **`reviewer`** (before the merge, by the acceptance reviewer), **`owner`** (at the click-through), or **`after merge`** (the owner and the orchestrator: live sessions, reinstalls, edits outside the repo), or **`skill-test`** (below), with its command or action and the result that counts as PASS.

## Skill tests

A plan that creates or changes a file in a skill's folder (its `SKILL.md`, or a file beside it that agents read) adds `skill-test` steps to its acceptance task: one per pressure scenario the spec names. When the spec names none, write them from the behaviour it changes, and list that among your deviations. Each step gives:

- **Situation:** everything a fresh agent needs, in full, since it sees only the skills and this text: who it is (the orchestrator, an executor, a planner), the repo's state, what has just happened, and what it is asked to answer.
- **GREEN:** what an agent reading the branch's skills must do, concretely enough to judge from its answer (the commands it would run and its next message).
- **RED:** what an agent reading `main`'s skills (or none, for a new skill) is expected to do instead.

The orchestrator runs each scenario on both, after acceptance and beside the code review (`hyper-relay:orchestrating`'s `reviewing.md`).

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces** (only when a later task uses what this one makes):
- Consumes: [what this task uses from earlier tasks: exact names and signatures]
- Produces: [what later tasks use: exact function names, parameters and return types]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice (which library call, which data structure); a code block only for an algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature" -m "Plan-Task: docs/superpowers/plans/<this plan>.md#<N>"
```
````

The **final** commit step of each task carries the plan's own path and the task's number as a git trailer, as above: `-m "Plan-Task: docs/superpowers/plans/<this plan>.md#<N>"`. Earlier commits in the same task and tasks with no commit step do not carry it.

The executor reads the whole plan, so a task has an **Interfaces** block only when a later task uses its names or types. The later task's steps point to that block instead of repeating its code.

## What a Step Contains

A step is done when the executor can write exactly one reasonable thing from it: unambiguous, not complete. Each kind of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them, and the setup its assertions depend on: which fixtures it calls, with which values.
- **A fixture:** a helper that writes test data is given as its signature (its name and arguments) and one sample of what it writes, as data, not as the code that writes it: for a record format, one record with every field the tested code reads, nested as the real format nests it, showing where each argument goes. The executor writes the helper. The test harness (pass and fail counters, assert helpers) is named by the existing suite whose harness to follow, not written out. A fixture is written in full only when its exact bytes are what the test checks: a cut-off line, an escape, a malformed record.
- **A code step:** the exact signature (name, parameters, return type), the file it lives in, and the values the spec pins. The executor writes the body. A body appears only for an algorithm the signature and the tests do not determine.
- **A text step:** the exact text, in full, and where it goes, wherever the words are the product: a skill file or a file beside it that agents read, a doc, a message a person or an agent reads, a config value. "Create X with exactly this content" and "Replace X with Y" are the forms for these. A test file is never a text step: "Create X with exactly this content" is for files whose words are the product.
- **A verification step:** the command, and the output that means it passed.
- **A reference to another task:** that task's Interfaces block, not a copy of its code.

A plan is the set of decisions the executor cannot make alone. A plan longer than the code it describes has written the code instead. Lines that decide nothing ("TBD", "TODO", "implement later", "fill in details", "handle edge cases", "add appropriate validation", "write tests for the above", "Similar to Task N", a type or function no task defines) are the opposite failure. The self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step lets the executor write exactly one reasonable thing, and carries no more than that. A line that decides nothing is a gap; a body the signature and the tests already determine is a transcript. Fix both. A fixture helper's body that its signature and sample already determine is a transcript; replace it. Text steps keep their text in full.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, a task's tests exercise it, or it is in Review Focus and its test, with its assertions, is in the test step of the task that owns the code.

**5. Proportion:** Compare the plan's length with the spec's. When code blocks are most of the plan, replace bodies with signatures, test names and assertions, and fixture helpers with their signature and a sample, and check that each step is still unambiguous. Text steps do not count against the plan here (a test file is never one).

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Committing the plan

Commit a plan only while the repo's main checkout is on `main`: there, `git branch --show-current` prints `main` and `git rev-parse -q --verify MERGE_HEAD` prints nothing. Stage each file by its path and commit just those: `git add <path>`, then `git commit -m "<message>" -- <path> [<path>...]`. If the commit prints a `quartz:` line, do what it says.

When the main checkout is on another branch, a plan is running there (a branch run). Do not commit, and do not edit a file that is already committed. Run `quartz link-doc <path>` on your new plan (it puts an uncommitted doc on its cards; skip it when your dispatch prompt says the repo does not use Quartz), and report that it is held back. The orchestrator commits it after that branch merges (`hyper-relay:orchestrating`'s `reviewing.md`, §5).

## After saving the plan

Commit it (above), report its path and task count to the orchestrator, and stop. Do not offer ways to execute it and do not start executing: the orchestrator checks the plan, stops for the owner, and runs the handoff (`hyper-relay:orchestrating`'s `planning.md` and `dispatching.md`).
