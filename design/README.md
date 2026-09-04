# design

Your screens go here. You make them yourself in Claude Design — the prompt for that is on the
Stage 3 page — and export them as HTML/CSS into this folder, one file per screen from `SPEC.md`.

Claude integrates them 1:1 (`ARCHITECTURE.md` §2): no rebuild, no refactoring, no "use as a
reference". Anything a screen does not cover comes from the Bulma components in the `bulma-ui` skill.

The task files from `/paultask` name these files by exact path, so the folder is filled before
`/paultask` runs.
