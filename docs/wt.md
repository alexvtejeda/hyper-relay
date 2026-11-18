# wt: a disposable stack for each worktree

`wt` gives a git worktree a Docker Compose stack of its own: its own containers, network, database, image tags, ports
and seed data. You can start a branch, click through it and throw it away, while your real stack, run from the main
checkout, keeps running untouched.

It ships with hyper-relay as `bin/wt`. Claude Code puts a plugin's `bin/` on its Bash tool's `PATH`, so once
hyper-relay is installed, agents run `wt` by name. For your own shell, symlink it from a clone (the
[README's Install section](../README.md#wt) shows how).

## Why a worktree can't simply run the project's stack

Making the worktree is quick (`git worktree add`). Running the project's own `docker compose up` from it is the
problem:

- **Container names.** A compose file that pins its project `name:` makes every checkout the same compose project, so
  `up` from a worktree acts on the real containers and the real database.
- **Image tags.** A tag such as `myapp-api:local` is shared: a worktree's build changes what the real stack starts
  from next time.
- **Ports.** The real stack already holds the default host ports.
- **`.env`.** It is gitignored, so a new worktree has none, and compose needs it.
- **Values that depend on ports.** An API URL or an allowed origin in `.env` names a port, and the worktree's ports
  are different.
- **Pinned networks.** A compose file that pins a subnet and fixed addresses clashes with the real stack's network.

`wt` handles each of these in an override file that it writes outside the repo. The project's own compose file does
not change.

## Requirements

- Linux, with a POSIX shell: `wt` is written for dash and runs as `#!/bin/sh`.
- git.
- Docker Compose 2.24.4 or later, for the `!override` YAML tag.
- `jq`, and `ss` (from iproute2).
- A compose file at the project's root (`compose.yaml`, `compose.yml`, `docker-compose.yaml` or
  `docker-compose.yml`), and a committed `.wt.conf` beside it (below).

## Commands

| Command | What it does |
|---|---|
| `wt new <branch> [--from <base>]` | Creates a worktree for `<branch>` under the main checkout. No containers. |
| `wt up` | In a worktree: builds and starts its stack, seeds it the first time, and prints its URLs. |
| `wt ls` | Lists every `wt` stack on this machine. |
| `wt down [name]` | Stops a stack and deletes its containers, database, images and state. |

### `wt new`

`wt new feat/add-login` creates the worktree `.worktrees/add-login` under the main checkout, wherever you run it from:
the folder is the branch with everything up to its first `/` dropped and any later `/` turned into `-`
(`fix/api/v2` gives `.worktrees/api-v2`). `.worktrees/` must be gitignored, or `wt new` refuses.

- A new branch starts from `<base>`, `main` by default.
- An existing branch is checked out as it is, and `--from` is ignored (`wt new` says so).
- Then it runs `WT_NEW_SETUP` from the new worktree's own `.wt.conf`, inside the new worktree. If that fails, the
  worktree stays, and `wt new` says so.

### What `wt up` does

1. **Refuses a main checkout.** In a worktree, git's directory differs from the repo's common one; in a main checkout
   they are the same. This is the check that keeps your real stack safe.
2. **Names the stack** `<project>-wt-<slug>`. `<project>` is the main checkout's folder name and `<slug>` the branch
   (the worktree's folder name, on a detached HEAD), each lowercased, with every run of other characters turned into
   `-`, and cut to 30 characters. Branch `Feat/Add_Thing` of `~/src/myapp` gives `myapp-wt-feat-add-thing`.
3. **Takes a slot.** A stack keeps the slot it has. A new one takes the lowest free number, and is refused when
   `WT_MAX_STACKS` stacks exist already; the refusal lists them, so you can choose one to `wt down`.
4. **Writes `.env`**, a copy of the `WT_ENV_BASE` file (`.env.example` by default), because compose needs one to read
   its config. A `.env` that `wt` did not create is never overwritten: `wt up` stops and asks you to move it away.
5. **Runs `WT_SETUP` once** per stack, from the worktree's root, and records that it succeeded. A later `wt up` does
   not run it again, so a setup step that generates keys never replaces the ones the running stack uses.
6. **Reads the compose file** with `docker compose config --format json`: its services, published ports, images,
   pinned subnets and fixed addresses.
7. **Allocates ports.** The stack's published ports, in order of service name, get `30000 + slot × 100 + n`, bound to
   `127.0.0.1`. A port something already listens on is skipped. A stack keeps its ports from one `wt up` to the next.
8. **Applies `WT_ENV`** to `.env`, filling in its placeholders.
9. **Writes the override**, in the stack's state folder:
   - `ports: !override` for each service that publishes ports, with the allocated ones;
   - `image: <repo>:wt-<slug>` for each service with both `build` and `image`, so the stack's builds never retag your
     real images;
   - when a network pins a subnet (at most one may), `10.77.<slot>.0/24` instead, with each fixed address on it moved
     into the new subnet, keeping its last number: `192.168.50.10` becomes `10.77.1.10` in slot 1.
10. **Builds and starts** the stack (`docker compose up --build -d`, with the override), then waits until every
    service is running, and healthy where it has a health check, and every one-off service (a migration, say) has
    exited 0. A container that exits non-zero fails `wt up` and is named; so is a wait longer than
    `WT_WAIT_SECONDS`.
11. **Seeds once.** When `WT_SEED_PROFILE` is set, and until a seed has succeeded, `wt up` also runs that compose
    profile and waits for its services to finish. Then it records the seed, so it never runs again over the stack's
    data.
12. **Prints the URLs**: `http://localhost:<port>` for each published port, by service.

Running `wt up` again rebuilds the same stack on the same ports and keeps its database. Each run writes `.env` afresh
from the base file and `WT_ENV` (steps 4 and 8): change those, not `.env`.

### `wt ls` and `wt down`

`wt ls` prints one line per stack: its name, how many of its containers run, its worktree, and then its URLs. A stack
whose worktree is gone is marked stale, with the `wt down <name>` that clears it.

`wt down` without a name acts on the current worktree's stack; with a name, it can clean up a stack whose worktree is
gone. It runs `docker compose down -v --remove-orphans` for the stack (so its database goes, and so do the seed
profile's containers), removes the stack's own `wt-` image tags, removes the `.env` that `wt up` wrote, and deletes
the stack's state.

## `.wt.conf`

Commit a `.wt.conf` at the project's root. `wt` sources it as shell from the root of the worktree it works on, so each
branch reads its own copy. These are the only keys it reads:

| Key | Default | Meaning |
|---|---|---|
| `WT_ENV_BASE` | `.env.example` | The file `.env` is copied from. |
| `WT_ENV` | none | `KEY=VALUE` pairs, separated by spaces or newlines, set in `.env`. A value cannot contain a space. |
| `WT_SEED_PROFILE` | none | The compose profile to run once, on a new stack. |
| `WT_SETUP` | none | A command `wt up` runs once per stack, from the worktree's root, before the build. |
| `WT_NEW_SETUP` | none | A command `wt new` runs in the new worktree, after creating it. |

**Placeholders.** In a `WT_ENV` value, `{web}` is the host port the stack gives the `web` service's first published
port, and `{ip:web}` is the `web` service's fixed address, after its move into the stack's subnet. Any service name
works in place of `web`.

**A `WT_ENV` key that is not in the base file is an error,** and so is an unknown placeholder: `wt up` names it and
stops before it builds anything. Otherwise a typo such as `CORS_ALLOWD_ORIGINS` would add a variable nothing reads,
and the failure would show up much later, as a request the browser blocks.

An example, for a project whose compose file has `api` and `web` services and a `seed` profile:

```sh
# .env starts as a copy of .env.example (the default, so this line could go).
WT_ENV_BASE=.env.example
# Run the seed profile once, on a new stack.
WT_SEED_PROFILE=seed
# In a new worktree: install the dependencies.
WT_NEW_SETUP='npm ci'
# Point the app at this stack's ports. Each key must already be in .env.example.
WT_ENV='PUBLIC_API_URL=http://localhost:{api}
ALLOWED_ORIGIN=http://localhost:{web}'
```

## State and limits

Three environment variables, read when `wt` runs (they are not `.wt.conf` keys):

| Variable | Default | Meaning |
|---|---|---|
| `WT_STATE_DIR` | `~/.local/state/wt` | Where each stack keeps its state, in `<stack>/`: its slot, its worktree's path, its ports, the override, its images, and whether its setup and seed have run. Outside every repo. |
| `WT_MAX_STACKS` | `3` | How many stacks may exist at once. |
| `WT_WAIT_SECONDS` | `300` | How long `wt up` waits for the services to be ready. |

## When something fails

| Failure | What `wt` does |
|---|---|
| No `.wt.conf` | Stops, before touching anything. |
| A bad `WT_ENV` key or placeholder | Stops before building, and names it. |
| The stack limit is reached | Stops, and lists the stacks. |
| The stack's name belongs to another worktree | Stops, and names that worktree. |
| `WT_SETUP` fails | Stops before building, and says so. It runs again on the next `wt up`. |
| The build, a migration or the seed fails | Exits non-zero and gives the logs command. The stack stays up for you to look at. A failed seed is not recorded, so the next `wt up` runs it again; when a half-done seed makes that unsafe, `wt down` then `wt up` starts clean. |
| A port is taken between allocation and start | Says so; the next `wt up` allocates new ports. |
| A worktree is removed while its stack runs | `wt ls` marks the stack stale. `wt` never removes a stack on its own. |

## Safety

- **It refuses a main checkout,** so it never touches the stack you run from there.
- **`.env` comes from the base file, never from your real `.env`,** so a stack holds no real secrets and cannot use
  them to reach a real outside service.
- **Seed data only.** It never copies a real database.
- **Ports bind to `127.0.0.1`.**
- **`wt down` refuses any name that is not a `wt` stack's (`<project>-wt-<slug>`), and any stack it holds no state
  for,** so it cannot act on a real stack. It removes only the stack's own `wt-` image tags, never shared images such
  as `postgres:16`.
