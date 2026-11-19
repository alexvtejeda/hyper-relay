# The blind review's second pass

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <START> and <REQUIREMENTS>,
appends one feature's blind review below this file, and pipes both to a fresh headless session in the
same detached worktree. -->

Below is a code review of the change `git diff <START>..HEAD -- api web mailer-worker` in the repository in
your working directory, checked against `<REQUIREMENTS>`. Reviews make mistakes both ways. Check every
finding against the code itself, one by one.

For each finding:

- Read the code it names, and whatever decides whether it is true: its callers, its tests, the
  requirement it cites.
- Decide **CONFIRMED** (the defect is real and reachable in the merged code) or **REFUTED** (it is not:
  the case is handled elsewhere, the path cannot be reached, or the requirement does not ask for it).
  Unsure is REFUTED, with what would settle it.
- Give the grade it deserves, which may be lower than the review's, by the same definitions: Critical (a
  requirement broken, data leaked or lost, a security hole), Important (a real defect a user or an
  operator would hit, or a requirement no test covers), Minor (the rest).

The review's rules hold for you too: no git history (`git log`, `git show`, `git blame`, `git reflog`), no
`docs/`, nothing outside this working directory but the requirements file, nothing run, nothing edited.

**Report** one line per finding, in the review's order:

    <n>. CONFIRMED | REFUTED, <grade>: <one-line title>. Evidence: <file:line and the fact that decides it>.

End with one line: `Confirmed: <c> Critical, <i> Important, <m> Minor`. Only confirmed Critical and
Important findings count as escaped defects.

## The review
