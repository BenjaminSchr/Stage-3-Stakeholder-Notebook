> **DRAFT — not final.** Under review by the owner. Nothing here has been built or run yet.

# Stakeholder Notebook — Stage 3

The Stage 3 repo of the Product Builder training. You fork it and build a small app with Claude
Code: one card per person, with role, what matters to them, the last conversation and open
commitments. Open it before the meeting, add two lines after.

There is no code in here and no recipe. There are the rules, the task, and a place for the screens.

## What is in here

```
.
├── CLAUDE.md            ← how Claude behaves (loaded every session)
├── AGENTS.md            ← how the work runs: PLAN → APPLY → UNIFY, tasks, Git
├── ARCHITECTURE.md      ← what it runs on: stack, one container, project layout
├── PATTERNS.md          ← what the code looks like
├── DATABASE.md          ← how data get in and out
├── SPEC.md              ← the task: purpose, data model, screens, search
├── FLOWS.md             ← what happens when
├── ACCEPTANCE.md        ← the acceptance criteria; the concept takes them over
├── design/              ← your screens from Claude Design land here
├── .paul/               ← concepts, tasks, log
│   ├── LOG.md           ← append-only, one line per task/session
│   └── tasks/
└── .claude/
    ├── settings.json    ← SessionStart hook
    ├── hooks/status.sh  ← reports where the project stands
    ├── commands/
    │   └── paultask.md  ← writes the task files from the approved concept
    └── skills/
        ├── docker-stack/    ← one container: Postgres (pgvector) + FastAPI
        ├── python-patterns/ ← sync FastAPI, psycopg2, Jinja2/HTMX, pytest
        └── bulma-ui/        ← Bulma 1.0.4 components
```

## How it runs

1. Start Claude Code and use the start prompt from the Stage 3 page — it reads the instruction set
   with you and fills in project name and UI language in `CLAUDE.md`.
2. Concept prompt from the Stage 3 page, in Plan Mode: `SPEC.md`, `FLOWS.md` and `ACCEPTANCE.md`
   become `.paul/concept_v1.md`. The concept takes the acceptance criteria over as Given/When/Then
   and is the done gate from then on. You approve it. Nothing gets built before that.
3. `/paultask` — the approved concept becomes task files in `.paul/tasks/`. Read the plain-language
   section of each one.
4. Build task by task: code, test, review, merge into `dev`.
5. `docker compose up -d --build`.

The two prompts live on the Stage 3 page, not in this repo. `/paultask` is the only command here.

## What is deliberately missing

- **Code.** No app, no example, no scaffold. That is the exercise.
- **A recipe.** Nothing walks you through it step by step. The rules and the task are the whole input.
- **The screens.** You make them yourself in Claude Design — prompt on the Stage 3 page — and put
  the HTML/CSS export into `design/` before `/paultask`. See `design/README.md`.

## What is untested

- The hook has been syntax-checked and run through its states outside a live session, never in one.
- `/paultask` has never produced a task file. It is derived from a command that works in a more
  complex private setup; everything specific to that setup was stripped out.
- Nobody has built the Stakeholder Notebook from this repo end to end. Whether the spec is
  buildable in the intended time is unverified.
- The instruction set is copied over with three changes: the database file renamed to
  `DATABASE.md`, the start command fixed to `docker compose up -d --build`, the base image fixed to
  `pgvector/pgvector:pg16`. It is unverified against a real build.

## Open questions

1. The Stage 3 page still says `docker compose up --build` and that the fork contains the screens.
   Both are out of date against this repo.
