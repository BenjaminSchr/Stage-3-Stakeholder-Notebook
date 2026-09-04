# Spec — Stakeholder Notebook

## Purpose

One card per person: role, what matters to them, last conversation, open commitments (yours and theirs). Open it before the meeting, add two lines after.

## Data model

**Person**
- Name
- Role
- Team / area
- What matters to them
- Notes (free text)
- Active (yes / no)
- Created at

**Conversation**
- Person
- Date
- Note

**Commitment**
- Person
- Text
- Direction: mine / theirs
- Due date
- Done

No further entities.

## Screens

**People list**
All people, search at the top. Shows name, role, team. Click opens the person card. New person created from here.

**Person card**
Person's details, recent conversations (newest first), open commitments. From here: log a conversation, add a commitment, mark a commitment done, deactivate the person.

**Add conversation/commitment**
Form for one person: conversation (date, note) or commitment (text, direction, due date). Flags missing required fields instead of discarding input.

**Open commitments (optional)**
All open commitments across all people, sorted by due date. Overdue ones stand out. Click leads to the person card.

## Search

Semantic search over notes and conversations. A phrase like "annoyed with onboarding" also finds "frustration during first login" — not only exact word matches. Embeddings come from a local model, `paraphrase-multilingual-MiniLM-L12-v2` — no external service. The vectors live in Postgres.
