# Requirements lists: the restating prompt

<!-- Fixed before either run starts. README.md in this folder, step 6, pipes this file and the two
design documents' paths to one headless session, once, for both features. -->

Two design documents are named at the end of this prompt, one per feature. Each was written in its own
style, and that style must not reach the reviewer who will check the code against it. Restate each one as
a plain requirements list.

For each document:

- List every requirement a reviewer could check in the code: the behaviour, who it affects, when it
  happens, what is stored or sent, permissions, limits, errors and edge cases, and what the document puts
  out of scope.
- One requirement per numbered line, in plain present-tense sentences ("An approver receives ...").
  Keep the document's facts and drop everything else.
- Leave out how the work was organized: no plans, tasks, steps, phases, reviews, reviewers, agents,
  commits, branches, cards, boards, tools or process names, and no paths of documents. Do not quote the
  document, and do not copy its headings, numbering, tables or decision labels.
- Use the same plain style and the same order for both (behaviour, then data, then permissions, then
  errors and edge cases, then out of scope), so the two lists read alike.

Write them to `~/sat-benchmark/blind/requirements-c1.md` and `~/sat-benchmark/blind/requirements-c2.md`
(with your home folder's full path), each headed `# Requirements: <the feature, in plain words>`, and
nowhere else. Report only the two paths.

## The documents
