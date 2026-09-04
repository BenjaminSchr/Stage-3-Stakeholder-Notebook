# Acceptance Criteria

Source for the acceptance criteria. The concept takes them over as Given/When/Then; from then on the concept is what "done" is checked against.

**Operation**
- Runs in Docker: `docker compose up -d --build` starts everything, no further step
- One container: the app and Postgres together
- Data live in Postgres, survive a container restart

**Function**
- Search uses embeddings — finds "annoyed with onboarding" for "frustration during first login" too
- All screens from the design are present and do what the flows say
- No data loss on bad input — the form flags what's missing

**Code**
- Dev branch, main stays clean; commits with readable messages
- README: three lines on how to start it, nothing more
- No setup junk: no unused files, no dead dependencies, no sample data in the code
- The instruction set is adapted to this project: project name and UI language filled in

## App-specific

- Overdue commitments stand out in the list (due date in the past, not done)
- Search finds a conversation by the meaning of the note, not only exact wording
- Deactivating a person hides them from active lists but deletes neither the person nor their conversations and commitments
- Every commitment shows a direction (mine / theirs) — no mixing in the display
- A person with no conversations or commitments shows an empty but working card, not an error
