---
name: docker-stack
description: Use whenever making Docker, container, or stack-level architecture decisions — the Dockerfile, docker/entrypoint.sh, compose.yaml, the single-container layout, or the Python/FastAPI/psycopg2/pytest hard rules. Quick lookup; the authority is ARCHITECTURE.md + DATABASE.md.
---

# docker-stack — Single-Container Quick Reference

One container: Postgres + FastAPI app, started by `supervisord`. Full detail: `ARCHITECTURE.md`
§3. DB init and schema: `DATABASE.md` §1. Workflow/roles: `AGENTS.md`.

---

## Tech Stack (Hard Rules — no back-and-forth)

- **Python 3.12**
- **FastAPI sync only** — no `async`/`await`
- **psycopg2**, raw SQL, parameterized (`%s`) — **no ORM, no SQLAlchemy, no Alembic**
- **pytest** for all tests
- **Docker** — always pin versions, **never `:latest`**
- **No CDN** — all assets local in `app/static/`

DB access only through `app/db_service.py` (see `DATABASE.md` §2). No direct psycopg2 anywhere else.

---

## Dockerfile — how it's built up

- Base image: `pgvector/pgvector:pg16`. Always — pgvector is part of the stack, not a concept decision.
- Python 3.12 installed on top of that base, version pinned.
- All pip packages pinned in `requirements.txt` — never unpinned, never `:latest`.
- `supervisord` is installed and configured to run two processes: Postgres and the FastAPI app
  (`docker/supervisord.conf`).

---

## Entrypoint — `docker/entrypoint.sh`

Runs once, on first boot only (idempotent):
1. `initdb` for the Postgres data directory.
2. Create the app role and database.
3. Apply `sql/init_schema.sql`.
4. Apply `sql/init_test_db.sql` — creates the test database in the same Postgres instance.

Details and rationale: `DATABASE.md` §1 and §4. Do not re-implement schema logic here — call
into the same SQL files.

---

## compose.yaml — one service

Exactly one service (`app`), one named volume for Postgres data, port 8000 as the only exposed
port (Postgres stays inside the container, never published). Full example: `DATABASE.md` §3.

```yaml
services:
  app:
    build: .
    container_name: <project>
    ports:
      - "8000:8000"
    env_file: .env
    volumes:
      - <project>_pgdata:/var/lib/postgresql/data
volumes:
  <project>_pgdata:
```

Start: `docker compose up -d --build` — one command, everything runs.

---

## Data & Config

- Postgres data lives in the named volume `<project>_pgdata` — survives container restarts.
- The app knows only `DATABASE_URL` (from `.env`) — no code difference between environments.
- Test DB (`<project>_test_db`) lives in the same Postgres instance, reachable only via
  `TEST_DATABASE_URL` — never `DATABASE_URL` in tests (`DATABASE.md` §4).
