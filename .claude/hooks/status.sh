#!/bin/sh
# SessionStart hook: reports where the project stands.
# Runs on macOS and under Git Bash on Windows. POSIX sh only, nothing bash-specific.

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

echo "## Project status"
echo

# --- 1. The instruction set ---
missing=""
for f in CLAUDE.md AGENTS.md ARCHITECTURE.md PATTERNS.md DATABASE.md; do
    [ -f "$f" ] || missing="$missing $f"
done
if [ -n "$missing" ]; then
    echo "Missing from the instruction set:$missing"
    echo "Say so before anything else — the rules are incomplete."
    echo
fi

# --- 2. Concept ---
concept=$(ls .paul/concept_v*.md 2>/dev/null | sort | tail -n 1)
if [ -z "$concept" ]; then
    echo "No concept yet. Start with the prompts from the Stage 3 page:"
    echo "first read the instruction set together, then Plan Mode for the concept."
    exit 0
fi
echo "Concept: $concept"

# --- 3. Tasks ---
tasks=$(ls .paul/tasks/*.md 2>/dev/null)
if [ -z "$tasks" ]; then
    echo "No tasks yet. If the concept is approved: \`/paultask\`."
    exit 0
fi

next=$(ls .paul/tasks/IN_PROGRESS_*.md .paul/tasks/TODO_*.md 2>/dev/null | head -n 1)
if [ -n "$next" ]; then
    echo "Next task: $next"
    exit 0
fi

open=$(ls .paul/tasks/FAILED_*.md .paul/tasks/BLOCKED_*.md 2>/dev/null | head -n 1)
if [ -n "$open" ]; then
    echo "Nothing to pick up, but this one stopped: $open"
    exit 0
fi

echo "All tasks done. \`docker compose up -d --build\`."
