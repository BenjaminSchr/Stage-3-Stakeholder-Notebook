# PATTERNS — Code Cookbook

> Concrete patterns to look up while coding. Infra in `ARCHITECTURE.md`,
> DB concept + `db_service.py` implementation in `DATABASE.md`.

---

## 1. DB Access (db_service)

No psycopg2 outside `app/db_service.py`. Reads via `query()`, writes via `get_conn_ctx()`.
Implementation: `DATABASE.md` §2 (not duplicated here).

**Reads:**
```python
from app.db_service import query

rows = query("SELECT * FROM items WHERE id = %s", (item_id,))
# rows is a list of dicts (RealDictCursor)
```

**Writes:**
```python
from app.db_service import get_conn_ctx

with get_conn_ctx() as conn:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id", (name,))
        new_row = cur.fetchall()   # BEFORE commit!
    conn.commit()
```

---

## 2. Config (pydantic-settings)

```python
# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    database_url: str
    test_database_url: str = ""
    app_port: int = 8000

    model_config = SettingsConfigDict(env_file=".env")


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

`get_settings()` is cached — one settings object per process.

---

## 3. Feature File Pattern (one feature = one file)

Structure:
```
app/
├── main.py                  ← app setup + routing only (no logic)
├── config.py                ← pydantic-settings
├── db_service.py            ← only DB access point
├── <feature>_feature.py     ← ALL logic of one feature (routes + queries + helpers)
├── static/
│   ├── bulma/css/bulma.min.css   (local, no CDN)
│   ├── css/custom.css
│   └── vendor/htmx.min.js
└── templates/
    ├── base.html            ← Bulma layout
    ├── pages/               ← full pages
    └── partials/            ← HTMX fragments
```

**main.py — routing only:**
```python
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.items_feature import router as items_router

app = FastAPI()
app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.include_router(items_router)


@app.get("/health")
def health():
    return {"status": "ok"}
```

**Feature file:**
```python
# app/items_feature.py
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from app.db_service import query, get_conn_ctx

router = APIRouter()
templates = Jinja2Templates(directory="app/templates")


# --- View: full page ---
@router.get("/items", response_class=HTMLResponse)
def items_page(request: Request):
    return templates.TemplateResponse("pages/items.html", {"request": request})


# --- API: JSON ---
@router.get("/api/items")
def get_items():
    rows = query("SELECT * FROM items ORDER BY created_at DESC")
    return {"items": rows}


# --- HTMX partial: HTML fragment ---
@router.get("/items/partial/list", response_class=HTMLResponse)
def items_list_partial(request: Request):
    rows = query("SELECT * FROM items ORDER BY created_at DESC")
    return templates.TemplateResponse(
        "partials/items_list.html", {"request": request, "items": rows}
    )


def _helper():  # internal helpers stay in the same file
    ...
```

**Adding a feature:** create `app/<feature>_feature.py` → all logic inside →
export `router = APIRouter()` → one line `app.include_router(...)` in `main.py`.

---

## 4. Jinja2 / Bulma Skeleton

No CDN — all assets local from `app/static/`. Bulma is CSS only, no JS bundle.

```html
{# templates/base.html #}
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{% block title %}App{% endblock %}</title>
  <link rel="stylesheet" href="/static/bulma/css/bulma.min.css">
  <link rel="stylesheet" href="/static/css/custom.css">
</head>
<body>
  <section class="section">
    <div class="container">
      {% block content %}{% endblock %}
    </div>
  </section>
  <script src="/static/vendor/htmx.min.js"></script>
</body>
</html>
```

**Page** extends `base.html`, loads content via HTMX:
```html
{# templates/pages/items.html #}
{% extends "base.html" %}
{% block content %}
<div class="box">
  <h1 class="title is-4">Items</h1>
  <div id="items-list" hx-get="/items/partial/list" hx-trigger="load" hx-swap="innerHTML">
    <p class="has-text-grey has-text-centered py-4">Loading…</p>
  </div>
</div>
{% endblock %}
```

**Partial** is a pure fragment — **never extends `base.html`:**
```html
{# templates/partials/items_list.html #}
<table class="table is-fullwidth is-striped">
  <thead><tr><th>Name</th><th class="has-text-right">Amount</th></tr></thead>
  <tbody>
    {% for item in items %}
    <tr><td>{{ item.name }}</td><td class="has-text-right">{{ "%.2f"|format(item.amount) }} €</td></tr>
    {% else %}
    <tr><td colspan="2" class="has-text-centered has-text-grey py-4">No entries</td></tr>
    {% endfor %}
  </tbody>
</table>
```

HTMX rules: partials live in `templates/partials/` and return fragments (no `extends`);
`hx-target` decides where the result goes; OOB swaps (`hx-swap-oob="true"`) for counters/badges
outside the main target.

---

## 5. pytest Patterns

**conftest.py** — redirects to the test DB BEFORE `app.main` is imported:
```python
# tests/conftest.py
import os
import pytest
from fastapi.testclient import TestClient

# TEST_DATABASE_URL is mandatory in tests — never test against the real DATABASE_URL.
os.environ["DATABASE_URL"] = os.environ["TEST_DATABASE_URL"]

from app.main import app  # noqa: E402 — import only after the env override


@pytest.fixture
def client():
    return TestClient(app)
```

**Integration test** (every new feature → mandatory):
```python
def test_health(client):
    assert client.get("/health").status_code == 200


def test_create_and_list_item(client):
    r = client.post("/api/items", json={"name": "Widget", "amount": 9.5})
    assert r.status_code == 200
    items = client.get("/api/items").json()["items"]
    assert any(i["name"] == "Widget" for i in items)
```

**Regression test** (every bug fix → mandatory, names the bug):
```python
def test_apostrophe_name_no_crash(client):
    """Regression: names with an apostrophe broke the SQL query (O'Brien)."""
    r = client.post("/api/items", json={"name": "O'Brien", "amount": 1.0})
    assert r.status_code != 500
```

---

## 6. Good vs. Bad — the classics

**SQL parameters:**
```python
# BAD — f-string: SQL injection, crashes on special characters
query(f"SELECT * FROM items WHERE name = '{name}'")

# GOOD — parameterized
query("SELECT * FROM items WHERE name = %s", (name,))
```

**INSERT … RETURNING:**
```python
# BAD — commit before fetch discards the result set
cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id", (name,))
conn.commit()
new_id = cur.fetchall()      # empty!

# GOOD — fetch BEFORE commit
cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id", (name,))
new_id = cur.fetchall()[0]["id"]
conn.commit()
```

**git add:**
```bash
# BAD — picks up unrelated changes, breaks task atomicity
git add .
git add -A

# GOOD — only the task's file(s), explicitly
git add app/items_feature.py tests/test_items.py
```

**File rename (task file → DONE):**
```bash
# BAD — leaves the original tracked, git sees delete + add
mv .paul/tasks/IN_PROGRESS_TASK_001_M1_T1_create-db-schema.md .paul/tasks/DONE_TASK_001_M1_T1_create-db-schema.md

# GOOD — git tracks the rename
git mv .paul/tasks/IN_PROGRESS_TASK_001_M1_T1_create-db-schema.md .paul/tasks/DONE_TASK_001_M1_T1_create-db-schema.md
```
