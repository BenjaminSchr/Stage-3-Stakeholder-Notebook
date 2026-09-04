# AGENTS.md — Full Workflow

> The full workflow. `CLAUDE.md` carries language + coding discipline; everything else is here.
> No duplicates between the two files.

## Skills (use autonomously — don't wait for the owner)
- `docker-stack` — Docker, FastAPI, PostgreSQL, architecture decisions
- `python-patterns` — FastAPI features, psycopg2 queries, Jinja2/HTMX, pytest
- `bulma-ui` — UI templates and components

**Rule:** Before you write code in one of these domains and haven't read the skill yet —
read it first, don't guess from memory.

---

## Roles

- **Claude = head and hands.** Writes concepts, creates branches, writes task files, types the
  code from the task files, reviews, decides merges, runs UNIFY.
- **Owner** reviews and approves concepts, accepts milestones, decides releases. Nothing else.

---

## The Loop: PLAN → APPLY → UNIFY

### PLAN — concepts only
- **Concept versioning:** every concept is its own file `concept_v1.md`, `concept_v2.md`, … —
  **never overwrite**, history stays.
- A concept contains: Objective, Acceptance Criteria (Given/When/Then), UI language, task
  breakdown (ordered list of tasks), boundaries.
- Where the project ships an `ACCEPTANCE.md`, the concept takes its criteria over as Given/When/Then.
  From then on the concept is the done gate; `ACCEPTANCE.md` stays the source, not a second gate.
- **DB mode (mandatory, always first):** exactly one line — `single-container` (app + Postgres in
  one container, default, see `DATABASE.md`) / `none`. Missing DB mode → concept incomplete.
- **Sanity check:** identify potential blockers in the concept and **resolve them during planning**.
  BLOCKED is not a planned waiting state.
- **PLAN produces ONLY concepts — never task files.**
- The owner reviews and approves the concept before tasks are written. Open questions are
  resolved before APPLY.

### APPLY — execution
- After concept approval: write task files via `/paultask` into `.paul/tasks/`.
- Tasks run **sequentially** (code → test → review → merge into `dev`).
- Ad-hoc fixes (<~30 lines, no new file, no feature): directly, without a task file.

### UNIFY — automatic once the last task of a milestone is merged into `dev`
No owner gate. Runs automatically after the milestone's last task → `dev` merge:
- **Milestone review** over `dev` since the last tag, in a **fresh session without the coder's
  context**: cross-task inconsistencies, duplicated code, missing tests, unjustified test changes.
  Verdict **RED** → fix tasks first; **GREEN** → continue.
- Write `SUMMARY.md` (plan vs. actual).
- Finalize `LOG.md` (append-only).
- Git clean: merged `task/*` branches removed (`git branch -d`), milestone tag set.
- Archive `concept_vX.md` → `.paul/archive/` (`git mv`).

---

## `.paul/` Structure

```
.paul/
  concept_v1.md   concept_v2.md   ← plans (never overwrite)
  LOG.md          ← chronological journal
  SUMMARY.md      ← plan vs. actual (UNIFY only)
  archive/        ← concepts of finished milestones (UNIFY only)
  tasks/
    TODO_TASK_001_M1_T1_create-db-schema.md
    DONE_BUG_002_M1_T2_fix-login-crash.md
```

### Mandatory File Updates (non-negotiable)
| File | Update WHEN |
|---|---|
| `LOG.md` | after every task completion/failure; after milestone review; after every session |
| `SUMMARY.md` | at UNIFY |

Status change = task file prefix renamed (e.g. `TODO_` → `DONE_`) + one `LOG.md` line.
No separate STATE file — status lives in the filename + Git.

### BLOCKED
Not a planned waiting state — blockers are resolved in the sanity check. The `BLOCKED_` prefix
exists only for real, unexpected hard stops during execution. Then: rename the task file to
`BLOCKED_`, reason in `LOG.md`, don't guess.

---

## `/paultask` — the only task command

### Task/Bug Naming — global running number, never reset, never reused
```
STATUS_TASK_GLOBALNR_MX_TZ_taskname.md
STATUS_BUG_GLOBALNR_MX_TZ_bugname.md
```
Status prefixes: `TODO_` / `IN_PROGRESS_` / `DONE_` / `FAILED_` / `BLOCKED_`

### Mandatory Fields
- **`**UI Language:** English | German`** — no default, never assume.
- **`**Test Type:**`** — exactly one: `unit` / `integration` (TestClient + DB) / `smoke`
  (curl / file-exists) / `none` (**must be justified explicitly**). Missing field → task incomplete.
- **`**Scope:**`** (mandatory) — list of allowed paths including the task's test file(s).
  **Exact paths, not directory globs** (`app/main.py`, not `app/*`). `.paul/` files (the task
  file itself, `LOG.md`) are always in scope. Before committing: `git diff --name-only` — files
  outside the scope → STOP + report.
- **`**Branch:**`** — the exact task branch (see Git). Missing → STOP, ask.

### Task File Rules
- One task = one file = **one-shot prompt.** Thinking happens at PLAN (once); execution follows
  the file without asking back.
- **100 % self-contained:** paste required patterns INTO the task (not "see PATTERNS.md"),
  files to read as explicit paths, always a DO-NOT-TOUCH list.
- **No open options:** "do A OR B" is a planning error — decide before writing.
- **Anchors verified only:** every file/function/line checked against real code, never from
  memory. A wrong instruction is worse than a vague one.
- At the top a **plain-language section** (what is being built, in simple words).
- **Tests come WITH the task:** feature → integration/unit test, bug fix → regression test —
  in the same task, test file listed in the scope.
- Never a task for <~10 lines — combine with a related task. Granularity: 3–6 AC → 3–6 tasks.
- Deleting task files: only with the owner's active permission.

---

## Milestones and Tasks

- **Milestone** = one concept/phase, contains an ordered list of tasks. Planning unit only — no
  branch; tasks merge into `dev`.
- **Task** = one unit of work on the files named in the scope.

### Setup Check (once per milestone, before the first task)
- [ ] `.env` present + all variables set (owner confirms real values)
- [ ] `requirements.txt` complete; container rebuilt and up (`docker compose up -d --build`)
- [ ] DB schema applied (`docker/entrypoint.sh` on first boot — `/health` answers)
- [ ] `docker compose exec app pytest --co -q` collects without errors

Only when the setup check is green → first task.

### Task End — fixed order
```
1. PYTEST     → docker compose exec app pytest tests/ -v  (full suite, on the task branch)
2. REVIEW     → per-task review against the task file (scope, tests, DO-NOT-TOUCH)
3. RENAME     → git mv TODO_/IN_PROGRESS_… → DONE_… + LOG.md line, one commit
4. MERGE      → task → dev --no-ff
```

---

## Git — 3-level hierarchy

```
main
└── dev
    └── task/GLOBALNR-MX-TZ-name   (bug/GLOBALNR-MX-TZ-name)
```

### Hard Rules
- Task branch is created from the **current `dev` HEAD** (all previous tasks already merged).
- Task → `dev` (`--no-ff`) is mandatory **before** the next task.
- Never commit directly on `main` or `dev` — exception: `.paul/` files
  (`LOG.md` after milestone review, `SUMMARY.md` and archive at UNIFY).
- One task = one branch. Never bundle tasks, never stack branches.
- Before commit: `git diff --name-only` — files changed outside the scope → STOP + report.
- Last commit on a task branch: task file renamed (`DONE_…` / `FAILED_…`) + `LOG.md` line.
  Only then merge into `dev`.

### Merge Flow
```
task/bug → dev    : pytest suite + per-task review
dev → main        : release by the owner (after UNIFY)
```
Only tested tasks go into `dev`. `main` = release.

### Test Integrity
- Tests come WITH the task (listed in scope); foreign `tests/**` are never touched.
- A green suite is not trustworthy if the coder was allowed to bend tests — every test change is
  justified in the milestone review: "tracks-contract" vs. "masks-a-bug".

### Commit Format
```
feat: TASK_001_M1-T1 — description
fix:  BUG_002_M1-T2 — description
test: TASK_003_M1-T3 — description
merge: TASK_001_M1-T1 → dev
```

### Git Permissions
Allowed: `git checkout [-b]`, `git add <path>`, `git commit`, `git mv`, `merge` task → dev
(`--no-ff`), `git push` (`dev`), `git branch -d` (merged only, UNIFY), `git tag` (UNIFY),
read-only (`status`/`diff`/`log`/`branch`).
Forbidden: `git add .`/`-A`/`commit -am` (breaks atomicity), `rebase`, `reset`, `stash`,
`cherry-pick`, `--amend`, `branch -D`, `--force`.

---

## Tech Stack
Hard rules live in `ARCHITECTURE.md` §1–3 (Python 3.12, FastAPI sync, psycopg2 raw SQL, pytest,
one-container Docker, Bulma 1.0.4 vendored, Claude Design output = final). DB rules, test DB and
SQL pitfalls: `DATABASE.md`. Code patterns: `PATTERNS.md`.
