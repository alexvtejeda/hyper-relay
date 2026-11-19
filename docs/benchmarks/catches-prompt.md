# In-process catches: the counter's prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, pipes this file and the list of
both runs' transcripts to one headless session. The owner checks its list. -->

Two runs built one feature each, one through hyper-relay's relay and one through upstream superpowers. In
each, reviewers checked the work before it merged. List every finding those reviewers raised and what
became of it. Do not judge the findings: count them.

**The input** at the end of this prompt lists transcript files, one per line: `<run> <role> <path>`. The
reviewer roles are the relay's `acceptance reviewer` and `code reviewer`, and superpowers' per-task
reviewers (`task reviewer`, or `spec reviewer` and `quality reviewer`) and `final reviewer`. The other lines
(`main`, `executor`, `implementer`) are where you find the outcomes.

Transcripts are JSON Lines and large: never read one whole. Print the text of its assistant messages with

    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' <path>

and search that output with `grep -n`.

**What counts as a finding:**

- The relay: each acceptance step a reviewer marked FAIL or NEEDS-HUMAN, and each issue of a code review
  (Critical, Important or Minor).
- Superpowers: each issue a per-task review raised, whatever it calls the review (spec compliance,
  quality, or both at once), and each issue of the final review of the whole branch.
- Not a finding: an executor's or implementer's own failing test on its way to green (test-driven
  development's red step), praise, or a passing check.

A finding raised again in a later round is one finding, not two.

**The outcome** of each: **fixed** (a later commit or report shows the change), **dropped** (the main
session or the owner decided not to act, or nobody acted on it), or **disputed** (someone argued it was
wrong, and it was not fixed). Quote where the outcome shows.

**Report** one table per run:

    ## <run>
    | # | Reviewer (role, agent id) | Task or step | Finding, one line | Severity as given | Outcome | Where the outcome shows |
    |---|---|---|---|---|---|---|

Then one line per run: `<run>: <n> findings: <f> fixed, <d> dropped, <x> disputed`.

## The transcripts
