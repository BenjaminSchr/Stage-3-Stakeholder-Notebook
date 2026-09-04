# DATABASE — Database Concept

> How every app gets its database. Code usage of the helpers in `PATTERNS.md`,
> container layout in `ARCHITECTURE.md`.

---

## 1. One Container

App and Postgres run in **one container**. No separate DB service, no external database.

- The image is based on `pgvector/pgvector:pg16` with Python 3.12 installed on top. pgvector is part
  of the stack, not a concept decision.
- `supervisord` starts two processes: Postgres and the FastAPI app.
- On first boot `docker/entrypoint.sh` runs `initdb`, creates role + database and applies
  `sql/init_schema.sql` and `sql/init_test_db.sql` (idempotent).
- The app reaches Postgres on `localhost:5432` inside the container. The only exposed port is
  the app port (`8000`).
- Data lives in a named volume so it survives restarts.

A concept declares the DB mode in one line: `single-container` (default) / `none`.

### Core rule: the app knows only `DATABASE_URL`
No code difference between environments. Everything is configured via `.env`.

---

## 2. `db_service.py` — the only DB access point

Every app has exactly one `app/db_service.py`. **No psycopg2 outside this file.**
Reads via `query()`, writes via `get_conn_ctx()`.

```python
# app/db_service.py
import psycopg2
from psycopg2.pool import ThreadedConnectionPool
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from app.config import get_settings

_pool: ThreadedConnectionPool | None = None


def _get_pool() -> ThreadedConnectionPool:
    """Lazily create the process-wide connection pool from DATABASE_URL."""
    global _pool
    if _pool is None:
        settings = get_settings()
        _pool = ThreadedConnectionPool(
            minconn=1,
            maxconn=10,
            dsn=settings.database_url,
            cursor_factory=RealDictCursor,
        )
    return _pool


@contextmanager
def get_conn_ctx():
    """Yield a pooled connection. Use for writes (call conn.commit() yourself)."""
    pool = _get_pool()
    conn = pool.getconn()
    try:
        yield conn
    except Exception:
        conn.rollback()
        raise
    finally:
        # Reset transaction state BEFORE returning to the pool. Without this a
        # SELECT-only query leaves the connection "idle in transaction", which
        # blocks schema drops (e.g. pytest teardown) on the next checkout.
        conn.rollback()
        pool.putconn(conn)


def query(sql, params=None):
    """READ helper. Returns a list of dict rows (RealDictCursor), or None for
    statements without a result set. For writes use get_conn_ctx() directly."""
    with get_conn_ctx() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            if cur.description:
                return cur.fetchall()
            return None
```

Why `ThreadedConnectionPool`: FastAPI sync endpoints run in a thread pool — the pool must be
thread-safe. `RealDictCursor` returns rows as dicts, directly usable in Jinja2/JSON.

---

## 3. `compose.yaml` — one service

```yaml
# compose.yaml
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

`.env`:
```
POSTGRES_PASSWORD=change-me
DATABASE_URL=postgresql://<project>_user:change-me@localhost:5432/<project>_db
TEST_DATABASE_URL=postgresql://<project>_user:change-me@localhost:5432/<project>_test_db
```

Start: `docker compose up -d --build`. One command, everything runs.

---

## 4. Test DB Rules

- `<project>_test_db` lives in the **same Postgres** as the dev DB (`sql/init_test_db.sql`
  creates database + schema, applied by `docker/entrypoint.sh`).
- Tests use **`TEST_DATABASE_URL` only** — **never `DATABASE_URL`**.
- The redirect happens in `conftest.py` (sets `DATABASE_URL = TEST_DATABASE_URL` before
  `app.main` is imported — see `PATTERNS.md`).
- Test run inside the container: `docker compose exec app pytest tests/ -v`

---

## 5. SQL Pitfalls (always)

- **`%s`, never `$1`/`$2`.** psycopg2 uses `%s` — `$1` is asyncpg syntax and crashes here.
- **`fetchall()` BEFORE `commit()`** on `INSERT ... RETURNING`. Commit first discards the result set.
- **Never f-strings or `.format()` in SQL.** Always parameterized (`%s` + params tuple) —
  otherwise SQL injection.
