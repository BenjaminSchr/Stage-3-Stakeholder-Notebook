---
name: python-patterns
description: Use whenever writing or modifying sync FastAPI code — feature files, db_service.py usage (query() / get_conn_ctx), pydantic-settings config, API/view/HTMX-partial routes, pytest tests, or SQL. Covers the standard patterns for sync FastAPI + raw SQL + HTMX (no ORM, no async). Full code cookbook: PATTERNS.md; DB implementation: DATABASE.md.
---

# python-patterns — Code Quick Reference

Sync FastAPI + psycopg2 (raw SQL) + Jinja2/HTMX. No ORM, no async.

Full patterns and code examples (feature-file layout, config, Jinja2/Bulma skeleton, pytest
fixtures): `PATTERNS.md`. DB implementation (`db_service.py`, connection pool, compose,
test DB): `DATABASE.md`. UI components: `bulma-ui` skill. Infra: `docker-stack` skill.

This skill does not duplicate those files — it only holds the reminders worth keeping in
short-term memory while coding.

---

## DB Access

No psycopg2 outside `app/db_service.py`. Reads via `query()`, writes via `get_conn_ctx()`.
Implementation: `DATABASE.md` §2.

```python
from app.db_service import query
rows = query("SELECT * FROM items WHERE id = %s", (item_id,))
```

```python
from app.db_service import get_conn_ctx

with get_conn_ctx() as conn:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id", (name,))
        new_id = cur.fetchall()[0]["id"]   # BEFORE commit!
    conn.commit()
```

---

## SQL Pitfalls (always check)

- **`%s`, never `$1`/`$2`.** psycopg2 uses `%s` — `$1` is asyncpg syntax and crashes here.
- **`fetchall()` BEFORE `commit()`** on `INSERT ... RETURNING`. Committing first discards the
  result set.
- **Never f-strings or `.format()` in SQL.** Always parameterized (`%s` + params tuple) —
  anything else is SQL injection.

---

## Feature Files

One feature = one `app/<feature>_feature.py` (routes + queries + helpers). `main.py` stays
routing-only. Full layout and route-type examples (view / API / HTMX partial): `PATTERNS.md` §3.

---

## Frontend

Jinja2 server-side rendering with HTMX partials. Pages extend `base.html`; partials never do.
Component snippets: `bulma-ui` skill. Base skeleton: `PATTERNS.md` §4.

---

## pytest

- `conftest.py` redirects `DATABASE_URL` to `TEST_DATABASE_URL` before `app.main` is imported.
  Never test against the real `DATABASE_URL`. Full fixture: `PATTERNS.md` §5.
- Every new feature → an integration test. Every bug fix → a regression test naming the bug.
- Tests run inside the container: `docker compose exec app pytest tests/ -v`.
- Test Type (task-mandatory field): `unit` / `integration` / `smoke` / `none` (must be
  justified explicitly).
