# The blind review

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <START> and <REQUIREMENTS>
and pipes this file to one headless session per feature, in a detached worktree at the feature's merge
commit. -->

You are reviewing one finished feature in the repository in your working directory, for defects that
reached its merged code. Review only the code change, against the requirements list.

**The change:** `git diff <START>..HEAD -- api web mailer-worker`. Read the changed files in full where you
need their context.

**The requirements:** `<REQUIREMENTS>`.

**Rules.**

- Do not read git history: no `git log`, `git show`, `git blame` or `git reflog`, and no commit messages.
  Do not read `docs/`, and read nothing outside this working directory except the requirements file.
- Do not run the app, its tests, a build or a container: read the code.
- Do not edit anything.

**What to look for:** a requirement not met, or met wrongly; a bug (a wrong condition, a missed case, a
race, an event sent twice or not at all); a permission or tenant-boundary hole; data reaching the wrong
person; an error swallowed; a path the requirements name that no test covers. Not style, not naming, not
suggestions.

**Grades.**

- **Critical:** a requirement is broken, data leaks or is lost, or there is a security hole.
- **Important:** a real defect a user or an operator would hit, or a requirement no test covers.
- **Minor:** anything else worth noting.

**Report** one entry per finding, worst first:

    ### <n>. <one-line title>
    Grade: <Critical | Important | Minor>
    Where: <file:line>
    Requirement: <its number in the requirements list, or "none">
    What is wrong: <what happens, and when>
    Evidence: <the lines of code, quoted, and the reasoning>

End with one line: `Findings: <c> Critical, <i> Important, <m> Minor`.
