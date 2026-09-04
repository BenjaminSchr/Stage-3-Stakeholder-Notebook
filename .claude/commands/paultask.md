---
description: Turns the approved concept into task files in .paul/tasks/. One task = one file = one self-contained prompt. Only runs after the concept is approved.
---

# /paultask — write the task files

You are the planner. You break the approved concept into task files that can be executed without
a single question back. The thinking happens here, once. Every ambiguity left in a task file is a
planning error.

Rules for naming, mandatory fields and task granularity live in `AGENTS.md`. This command applies
them; it does not restate them.

---

## 1. Gate — the concept has to be approved

1. Read the **highest-numbered** `.paul/concept_v*.md`. That is the source: objective, acceptance
   criteria (Given/When/Then — the done gate for every task; `ACCEPTANCE.md` is their source, not a
   second gate), UI language, DB mode, task breakdown, boundaries.
2. Check that it is approved — an approval line in the concept itself, or an entry in
   `.paul/LOG.md`. **If that is unclear, ask the owner and stop.** No task files before approval.
3. Read `.paul/LOG.md` and list `.paul/tasks/` — the filename prefixes carry the status and the
   numbers already used. There is no state file.

---

## 2. Split — INVEST and SPIDR

**INVEST** per task: Independent (buildable without its sibling), Negotiable (what plus acceptance,
not every line), Valuable, Estimable, Small (~3-6 files, one session), Testable (done-when is an
executable check).

**SPIDR** when a task busts the S limit, checked in this order: **S**pike (unclear → a read-only
research task first) · **P**aths (create / edit / delete → one path per task) · **I**nterfaces
(API vs. page vs. HTMX partial → one task each) · **D**ata (schema first) · **R**ules (simple
version first, rules as follow-ups).

**One file, one task.** Each file is edited by exactly one task. If a split would put two tasks on
the same file, split the file by responsibility instead: one feature = one `app/<feature>_feature.py`
with its own `APIRouter`, and `main.py` gets one include line per feature.

**Granularity:** 3-6 acceptance criteria → 3-6 tasks, not 10-15. Never a task for under ~10 lines —
combine it with a related one.

---

## 3. Number and name

The global number works like a ticket id: never reset, never reused. Scan `.paul/tasks/` across all
status prefixes and both types (`*_TASK_<NNN>_*` and `*_BUG_<NNN>_*`), take the highest and add one.
Empty or missing folder → start at `001`. Always three digits.

```
TODO_TASK_001_M1_T1_create-db-schema.md
TODO_BUG_002_M1_T2_fix-empty-form-crash.md
```

New files always get `TODO_`. Branch: `task/001-M1-T1-create-db-schema` (`bug/…` for bugs).
Commit format: `feat: TASK_001_M1-T1 — description`.

> Underscores in the filename, dashes in the branch and the commit. That is the convention — don't
> "fix" it.

---

## 4. One-shot rules for every task file

- **One task = one file = one prompt.** One run, no questions back.
- **100 % self-contained:** paste the patterns the task needs **into** the file as snippets —
  never "see `PATTERNS.md`" as the only reference. Files to read are named by exact path. There is
  always a do-not-touch list.
- **No open options.** "Do A or B" is a planning error. Decide before writing.
- **Verified anchors only:** every file, function and line checked against the real code while
  planning, never quoted from memory. A confidently wrong instruction does more damage than a
  vague one.
- **Roughly 80 % specification, 20 % typing.** Architecture decisions (a new table, a pattern, an
  endpoint contract) belong in the task. Implementation details (variable names, loop shape) do not.

---

## 5. Mandatory fields (missing one = incomplete, don't ship it)

- **`UI Language:`** — `English` or `German`. No default, never assumed.
- **`Test Type:`** — exactly one of `unit` / `integration` (TestClient + DB) / `smoke` (curl or
  file-exists) / `none`, and `none` carries a `Justification:` line.
- **`Scope:`** — the exact paths this task may commit, including its own test file. Exact paths,
  not directory globs (`app/main.py`, not `app/*`). Everything else is off limits: other tests,
  `.env`, other task files.
- **`Branch:`** — the exact branch name from §3.

**Tests come with the task.** A feature brings its integration or unit test, a bug fix brings a
regression test that names the bug — same task, same scope, test file listed in the scope. Tests
outside the scope stay untouched. For endpoints that write data, at least two failure-mode criteria
in Given/When/Then form: empty input, duplicates, boundary values.

---

## 6. Task file template

```
# TASK_NNN_MX-TZ — <imperative title>          (bug: BUG_NNN_MX-TZ)

**Branch:** task/NNN-MX-TZ-<slug>
**UI Language:** English | German
**Test Type:** unit | integration | smoke | none    # none → Justification line
**Scope:** app/<feature>_feature.py, tests/test_<feature>.py

## In plain language
<1-2 sentences: what gets built, in normal words. The owner reads this section.>

## What changes
<2-4 sentences: what the system can do after this task that it could not before.>

## Read first
<Exact paths, and the line ranges that matter. Only what is needed.>

## Fixed decisions
<Tables, endpoints, contracts — everything that is not up for interpretation.
Required patterns pasted in here as snippets. No open options.>

## Anchors (verified)
<Per change: file + function + roughly which line, checked against the real code,
plus the target signature or the SQL verbatim.
psycopg2 uses %s, never $1. fetchall() before commit() on INSERT ... RETURNING.>

## Steps
<Concrete list.>

## Test cases
<Enumerated, including the failure-mode criteria. The coder types them, it does not design them.>

## Do not touch
<Off limits: tests outside the scope, .env, other task files, anything outside Scope.>

## Verify
<One test file: docker compose exec app pytest tests/test_<feature>.py -v
The full suite runs at the end of the task, see AGENTS.md.>

## Done when
<1-3 verifiable conditions.>
```

---

## 7. After writing

Append one line to `.paul/LOG.md`: `/paultask`: created TASK_NNN … TASK_MMM for M<X>, with the date.
Without that line the task creation is not finished.

---

## 8. Self-check before you hand over

- [ ] Concept was approved; highest `concept_v*.md` read.
- [ ] Global number = highest existing + 1, three digits, nothing reused.
- [ ] INVEST holds for every task; SPIDR applied where it did not.
- [ ] No file is edited by more than one task.
- [ ] All four mandatory fields set on every task.
- [ ] Scope = exact verified paths; no task lists foreign tests or `.env`.
- [ ] Every feature and bug task carries its own test, test file in the scope.
- [ ] Anchors verified against the real code; no open options; patterns pasted in.
- [ ] `LOG.md` updated.

---

## 9. Hand over

Print the list of task files you created, then this line:

```
Read the plain-language section of each task. Then: `Start with TASK_001`.
```
