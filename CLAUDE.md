# CLAUDE.md — Global Instructions

> Always loaded. Short layer only: language, coding discipline, anti-patterns.
> The full workflow lives in `AGENTS.md` — no duplicates here.

@AGENTS.md

## Project

Project name: <PROJECT NAME>
UI language: <English | German>

## Language
- Conversation: the user's language. **Output (code, comments, commits, docs, configs): English.**
- User-facing text in apps: decided per project — stated explicitly in the concept and in every task
  (`UI Language` field, see `AGENTS.md`), never guessed.

## Coding Discipline

### Karpathy Guidelines (apply to every line)
1. **Think Before Coding** — Make assumptions explicit. If something is unclear or has several
   interpretations: stop, name it, ask. Sycophantic agreement is failure.
2. **Simplicity First** — Minimum code that solves the problem. Nothing speculative, no unrequested
   features, no abstraction for single use, no error handling for impossible cases.
   200 lines where 50 would do → rewrite.
3. **Surgical Changes** — Touch only what the task requires. Match existing style. Clean up your own
   orphans (unused imports/vars caused by your edits). Do NOT touch pre-existing dead code —
   mention it, don't delete it.
4. **Goal-Driven Execution** — Define success criteria (declarative, not step-by-step), loop until verified.

### Planning Principles
**KISS** (simple) · **YAGNI** (don't build speculatively) · **DRY** (don't repeat) ·
**INVEST** (task splitting) · **SPIDR** (story splitting). Task granularity: `AGENTS.md` → Task File Rules.

### Risk
Overhead is insurance, not waste. **Risk is assessed in the concept** — for each undertaking,
estimate the maximum damage if it fails and set the review depth accordingly. Detailed planning
solves problems up front. **Never "come on, it's small"** — decide explicitly in the concept.

### Anti-Patterns (always refuse)
- "While we're here, let me also…" → No, separate task
- "I'll make this flexible for future use" → No, single-use is fine
- "This is probably what you meant" → Ask, don't assume
- "I think this works" without a test → Not done
- Removing code you don't understand → Stop, ask
