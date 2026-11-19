# Sealed pitfall list: the checker's prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, fills <C1_MERGE> and <C2_MERGE>,
appends the sealed list below this file, and pipes both to one headless session in the product's main
checkout, after both features have merged. The owner confirms its answers. -->

Below is a checklist written before two features were built: section C.1's checks are for the first
feature, section C.2's for the second. Check every item on the merged code of its own feature: C.1's at
commit `<C1_MERGE>`, C.2's at commit `<C2_MERGE>`. Read a file at a commit with `git show <commit>:<path>`
and search with `git grep <pattern> <commit> -- <paths>`. Where an item says to run a test, read the test
and the code instead: do not run tests, builds or the app, and do not edit anything.

For each item answer **yes** (the pitfall was avoided), **no** (it was not) or **unclear**, with the
evidence: the file and lines, or the search and what it found.

**Report** one table per feature:

    ## C.1
    | # | Check | Answer | Evidence |
    |---|---|---|---|

Then one line per feature: `<feature>: <y> yes, <n> no, <u> unclear`.

## The checklist
