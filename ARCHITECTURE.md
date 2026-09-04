# ARCHITECTURE — Tech Stack

> Infra and stack layer. DB details in `DATABASE.md`, code patterns in `PATTERNS.md`,
> workflow and roles in `AGENTS.md`.

---

## 1. Tech Stack (Hard Rules)

Non-negotiable. Followed without asking.

- **Python 3.12**
- **FastAPI sync only** — no `async`/`await`
- **psycopg2**, raw SQL, parameterized queries (`%s`) — **no ORM, no SQLAlchemy, no Alembic**
- **pytest** for all tests
- **Docker** — one container (see §3), always pin versions, **never `:latest`**
- **No CDN** — all assets local in `app/static/`

DB access exclusively through one central `app/db_service.py` (see `DATABASE.md`).
No direct psycopg2 outside of it.

---

## 2. Frontend

**Jinja2 server-side rendering** with **HTMX** for partials (see `PATTERNS.md`).

| Library | Version |
|---|---|
| Bulma | 1.0.4 |
| HTMX | 2.0.4 |

Both are vendored at project setup: `bulma.min.css` → `app/static/bulma/css/`, `htmx.min.js` →
`app/static/vendor/`. No build step. Bulma is CSS only.

### Claude Design output = final
If a design comes from Claude Design (HTML/CSS/JS) → **integrate it 1:1**.
No rebuild, no refactoring, no "use as a reference".

---

## 3. Docker — one container

App and Postgres run in **one container**, started by `supervisord`. One `compose.yaml`,
one service, one command: `docker compose up -d --build`. Details in `DATABASE.md`.

| Item | Convention |
|---|---|
| Container | `<project>` |
| Base image | `pgvector/pgvector:pg16` + Python 3.12, pinned |
| Exposed port | `8000` (app only — Postgres stays inside) |
| Data | named volume `<project>_pgdata` |

---

## 4. Project Layout

```
<project>/
├── app/
│   ├── main.py              ← app setup + routing only
│   ├── config.py            ← pydantic-settings
│   ├── db_service.py        ← only DB access point
│   ├── <feature>_feature.py ← one file per feature
│   ├── static/              ← bulma/, css/, vendor/htmx.min.js
│   └── templates/           ← base.html, pages/, partials/
├── docker/
│   ├── entrypoint.sh        ← initdb + schema on first boot
│   └── supervisord.conf     ← starts postgres + app
├── sql/
│   ├── init_schema.sql
│   └── init_test_db.sql
├── tests/
├── .paul/                   ← concepts, tasks, log (see AGENTS.md)
├── Dockerfile
├── compose.yaml
├── requirements.txt
├── .env.example
├── CLAUDE.md
├── AGENTS.md
├── ARCHITECTURE.md
├── PATTERNS.md
└── DATABASE.md
```
