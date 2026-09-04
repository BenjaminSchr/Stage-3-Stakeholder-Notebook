---
name: bulma-ui
description: Use whenever building or modifying UI with Bulma 1.0.4 in Jinja2 templates — the base.html skeleton, or core components (card, table, tag, input, button, level, notification, navbar). Covers local asset setup (no CDN, ever) and HTMX partial conventions.
---

# bulma-ui — Bulma 1.0.4 Quick Reference

Server-side Jinja2 + Bulma 1.0.4, HTMX for partials. **No CDN, ever — all assets local.**
Bulma is CSS only — it ships no JS bundle. Route wiring: `python-patterns` skill. Base
skeleton also in `PATTERNS.md` §4.

---

## Rules

1. Every full page extends `templates/base.html`.
2. Partials (HTMX fragments) **never** extend `base.html` — fragment only.
3. All assets served from `/static/` — vendored at project setup
   (`bulma.min.css` → `app/static/bulma/css/`), no CDN.
4. No React/Vue/npm/build step.

---

## base.html Skeleton

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

---

## Card

```html
<div class="card">
  <div class="card-header"><p class="card-header-title">Title</p></div>
  <div class="card-content"><div class="content">…</div></div>
  <footer class="card-footer"><a class="card-footer-item" href="#">Action</a></footer>
</div>
```

`box` is the lighter alternative when a card's header and footer are not needed.

## Table

```html
<table class="table is-fullwidth is-striped is-hoverable">
  <thead><tr><th>Name</th><th>Role</th></tr></thead>
  <tbody>{% for row in rows %}<tr><td>{{ row.name }}</td><td>{{ row.role }}</td></tr>
  {% else %}<tr><td colspan="2" class="has-text-centered has-text-grey py-4">No entries</td></tr>
  {% endfor %}</tbody>
</table>
```

## Tag

```html
<span class="tag is-success">Active</span> <span class="tag is-danger">Error</span>
```

## Input / Textarea / Button

```html
<div class="field">
  <label class="label">Name</label>
  <div class="control"><input class="input" type="text" name="name" required></div>
</div>
<div class="field">
  <label class="label">Notes</label>
  <div class="control"><textarea class="textarea" name="notes"></textarea></div>
</div>
<button class="button is-primary">Save</button>
```

## Level

```html
<div class="level"><div class="level-left">Left</div><div class="level-right">Right</div></div>
```

## Notification

```html
<div class="notification is-warning">Overdue.</div>
```

## Navbar

```html
<nav class="navbar" role="navigation">
  <div class="navbar-brand"><a class="navbar-item" href="/">App</a></div>
  <div class="navbar-menu"><div class="navbar-start">
    <a class="navbar-item" href="/people">People</a></div></div>
</nav>
```

---

## HTMX

- Page extends `base.html`, loads content via `hx-get`/`hx-trigger`/`hx-swap`.
- Partial is a pure fragment in `templates/partials/` — no `extends`.
