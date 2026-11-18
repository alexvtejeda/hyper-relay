#!/usr/bin/env python3
"""PreToolUse guard for a generated planner agent (active only while it runs).

Bash: only read-only git, plus `git add`/`git commit` of plan files, plus
`quartz link-doc`. No shell operators, no `git -c`.
Write/Edit: only Markdown files under docs/superpowers/plans/.

Exit 2 = refuse (stderr is shown to the planner as the reason). Exit 0 = let the
normal permission flow continue.
"""
import json
import os
import shlex
import sys

PLANS = "/docs/superpowers/plans/"
READ_ONLY = {
    "status", "log", "show", "diff", "rev-parse", "ls-files", "ls-tree", "grep",
    "blame", "merge-base", "cat-file", "for-each-ref", "describe", "shortlog",
}
BRANCH_OK = {"--show-current", "--list", "-a", "--all", "-r", "--remotes", "-v", "-vv",
             "--merged", "--no-merged", "--contains", "--no-color"}
COMMIT_BAD = {"-a", "--all", "--amend", "--no-verify", "-n", "--fixup", "--squash"}


def refuse(msg):
    print(f"planner guard: {msg}. Planners may run only read-only git, "
          f"`git add`/`git commit` of plan files, and `quartz link-doc`; "
          f"and may write only {PLANS}*.md.", file=sys.stderr)
    sys.exit(2)


def is_plan_path(p):
    p = os.path.realpath(p)
    return PLANS in p and p.endswith(".md")


def check_bash(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|<>()")
    lex.whitespace_split = True
    try:
        toks = list(lex)
    except ValueError:
        refuse("could not parse the command")
    if not toks:
        refuse("empty command")
    if any(t and set(t) <= set(";&|<>()") for t in toks):
        refuse("shell operators (; && || | > < subshells) are not allowed; run one command per call")
    if "`" in cmd or "$(" in cmd:
        refuse("command substitution is not allowed")

    if toks[:2] == ["quartz", "link-doc"]:
        if len(toks) == 3 and is_plan_path(toks[2]):
            return
        refuse("`quartz link-doc` takes exactly one plan path")
    if toks[0] != "git":
        refuse(f"`{toks[0]}` is not allowed")

    # Global options before the subcommand: only -C <path> and --no-pager.
    i = 1
    while i < len(toks) and toks[i].startswith("-"):
        if toks[i] == "-C" and i + 1 < len(toks):
            i += 2
        elif toks[i] == "--no-pager":
            i += 1
        else:
            refuse(f"git option `{toks[i]}` is not allowed")
    if i >= len(toks):
        refuse("no git subcommand")
    sub, args = toks[i], toks[i + 1:]

    if any(a.startswith("--ext-diff") or a.startswith("--output") for a in args):
        refuse("`--ext-diff` / `--output` are not allowed")
    if sub in READ_ONLY:
        return
    if sub == "branch":
        # Bare `git branch` lists. Otherwise the FIRST arg must be a listing flag
        # (so `git branch newname` cannot create one) and every flag must be one.
        if not args or (args[0] in BRANCH_OK and all(a in BRANCH_OK for a in args if a.startswith("-"))):
            return
        refuse("only listing forms of `git branch` are allowed")
    if sub == "worktree":
        if args[:1] == ["list"]:
            return
        refuse("only `git worktree list` is allowed")
    if sub == "add":
        paths = [a for a in args if a != "--"]
        if paths and all(not a.startswith("-") and is_plan_path(a) for a in paths):
            return
        refuse("`git add` may stage only plan files, by path")
    if sub == "commit":
        if any(a in COMMIT_BAD or a.startswith("--amend") for a in args):
            refuse("`git commit` may not use -a/--all/--amend/--no-verify")
        # Must name its files after `--`, all plans: a bare commit would also take
        # whatever the owner has staged in the shared main checkout.
        if "--" in args:
            paths = args[args.index("--") + 1:]
            if paths and all(is_plan_path(p) for p in paths):
                return
        refuse("commit as `git commit -m \"<msg>\" -- <plan path>` (plan files only)")
    refuse(f"`git {sub}` is not allowed")


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {}) or {}
    if tool == "Bash":
        check_bash(inp.get("command", ""))
    elif tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        path = inp.get("file_path") or inp.get("notebook_path") or ""
        if not is_plan_path(path):
            refuse(f"writing `{path}` is not allowed")
    sys.exit(0)


if __name__ == "__main__":
    main()
