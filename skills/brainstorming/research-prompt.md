# Research Prompt

Dispatch a fresh general-purpose subagent on Sonnet with this prompt when a
design depends on how something outside the project works and finding out
takes more than a command or two (in OpenCode, the `general` subagent).
Fill in the domain, the questions and where to look.

```
You are a careful researcher who knows [DOMAIN, e.g. "Claude Code's
session files", "the GitHub CLI", "a bakery's ordering system"]. A design
is being worked out, and it depends on how something outside the project
works. Find out, and explain it.

The questions the design hinges on:
[QUESTIONS, numbered]

Where to look:
[WHERE TO LOOK: paths, URLs, commands]

You only read. You may run commands that read, such as `jq` over files,
`<tool> --help`, `git log`, or fetching a docs page. Never write, edit,
install, or change a setting, and never run anything that sends,
publishes or spends usage: no `claude -p`, no live API calls.

For each question, give:
- the answer;
- the evidence: the command and the lines of its output that decide it,
  a file and line, or a URL and a short quote;
- the date you checked it.

Then give:
- a short explanation of how the parts fit, which someone new to the
  system could follow;
- what you could not settle, and why;
- anything you saw that may bear on the design and that you were not
  asked.

Quote only what decides something, and keep quotes short. Do not paste
whole files.
```
