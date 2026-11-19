# Sealed pitfall list: the writer's brief

<!-- Fixed before either run starts. README.md in this folder, step 2, pipes this file and the two cards
to one headless session in the product's main checkout; nothing else goes into its prompt. -->

You are writing a sealed checklist. Two features of the product in your working directory will be built
after you finish, and your list will be used to check the merged code of each. Nobody reads it before
then, so write it for a checker who will have only the merged code and this list.

## What to read

- `CLAUDE.md` at the top of the working directory: the product's rules and conventions.
- The two feature cards at the end of this prompt, C.1 and C.2.
- The code of the notifications foundation both features build on: its registry, its `Publish` path and
  the inbox (what the pieces called Notifications A and Notifications B added). Find it with `grep`.

Read nothing else: not `docs/`, not git history, not another project. Do not run the app or its tests.

## What to write

For each feature, 6 to 10 pitfalls: mistakes a careful engineer could still make building that feature on
this foundation. For example: a recipient set that is too wide or too narrow, an event published twice or
not at all, a permission not checked, a tenant boundary crossed, a path the card names that no test
covers. Prefer what would matter to a user over matters of style.

Each pitfall is one yes/no check on the merged code, phrased so that **yes means the pitfall was
avoided**, with how to check it: a file to read, a `grep` to run, or a test to read. A checker must be
able to answer it without asking anyone.

Use exactly this form:

    # Sealed pitfalls

    ## C.1: <the card's title>

    1. **<the check, as a yes/no question>**
       How to check: <a file, a grep, or a test>.
       Yes when: <what the checker must see>.

    ## C.2: <the card's title>

    1. ...

## Where to save it

Write the list to `~/sat-benchmark/pitfalls.md` (with your home folder's full path) and nowhere else. Then
run `sha256sum` on it.

## What to report

Only two things: the file's path and the `sha256sum` line. Do not quote, summarize or count the pitfalls in
your reply: whoever reads it must not learn them before the scoring.

## The cards
