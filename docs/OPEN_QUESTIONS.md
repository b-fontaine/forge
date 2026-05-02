# Tracking Open Questions

<!-- Audit: F.1 (f1-open-questions, FR-OQ-019) -->

This guide complements the standard
[`global/open-questions.md`](../.forge/standards/global/open-questions.md)
(F.1 — Open Questions Tracking). It is aimed at contributors and
adopters who want to use the convention in their own changes.

## Why

Article III.4 of the Forge Constitution requires the marker
`[NEEDS CLARIFICATION: <question>]` whenever an agent or contributor
cannot resolve an ambiguity. F.1 mechanises this discipline with a
per-change file `open-questions.md` that tracks each question's
lifecycle (open → answered or wontfix), plus two enforcement gates :

- **`verify.sh` Open Questions Gate** — blocks archival of a change
  with at least one `Status: open` question.
- **`constitution-linter.sh` NEEDS CLARIFICATION rule** — blocks any
  `implemented` or `archived` change that still contains
  `[NEEDS CLARIFICATION:]` inline in `proposal.md` / `specs.md` /
  `design.md` / `tasks.md`.

This audit trail prevents silent loss of decisions ("why was X chosen
over Y in 2024 ?") and prevents archive-with-loose-ends.

## When to raise

Raise a question **as soon as the ambiguity surfaces**, not later.
Common moments :

- During `/forge:specify` — a requirement has multiple equally-valid
  interpretations.
- During `/forge:design` — an ADR has multiple options and the
  rationale isn't obvious.
- During `/forge:plan` — a task can be implemented in two different
  ways with different trade-offs.
- During `/forge:implement` — an edge case emerges from the actual
  code (rare, but should redemote the change to `planned` if so).

Don't defer the question to "later in the proposal". Capture it
immediately in `open-questions.md` (and inline as
`[NEEDS CLARIFICATION:]` if a paragraph in `specs.md` is affected).

## How to raise

1. Open `.forge/changes/<your-change>/open-questions.md` (created
   by `/forge:propose` ; if missing, copy from
   `.forge/templates/open-questions.md.tmpl`).
2. Find the next free Q-NNN identifier (highest used + 1, never
   reused).
3. Append a block following the schema :

```markdown
## Q-007: Should we use library X or library Y?

- **Status**: open
- **Raised in**: design.md
- **Raised on**: 2026-04-30
- **Raised by**: alice@team

### Question

Library X provides feature A but locks us into vendor V.
Library Y is open-source but has only 60% of A's coverage.
Which trade-off do we accept ?
```

4. If the question affects a `specs.md` paragraph, also write an
   inline `[NEEDS CLARIFICATION: see Q-007 in open-questions.md]`
   marker in the affected location. The marker MUST be resolved
   (replaced) before the change reaches `implemented`.

## How to resolve

When the maintainer or user makes a decision :

1. Flip the question's `Status: open` to `answered` (or `wontfix`
   if it's deferred / invalidated).
2. Add a `### Resolution` block :

```markdown
### Resolution

- **Resolved on**: 2026-05-02
- **Resolved by**: bob@team
- **Decision**: Use library Y, accept 40% gap and write our own thin layer.
- **Rationale**: vendor lock-in cost > coverage gap cost over 3-year horizon.
- **Resolved in**: design.md § ADR-005
```

3. Replace the inline `[NEEDS CLARIFICATION:]` marker in the
   `*.md` files with the resolved text.
4. Run `bash .forge/scripts/verify.sh` and
   `bash .forge/scripts/constitution-linter.sh` to confirm the
   change can now move forward.

## How to list across the project

The `forge-questions.sh` script aggregates open questions across all
changes :

```bash
# List every open question, sorted by Raised on (asc).
bash bin/forge-questions.sh

# Filter by change name.
bash bin/forge-questions.sh --change f1-open-questions

# Filter by status (open|answered|wontfix). Default is open.
bash bin/forge-questions.sh --status answered
```

Output format :

```
<change>:<Q-NNN>  <title>  (raised <date> by <handle>)
```

Useful for weekly triage : "what are the questions blocking us ?"

## How to handle in-flight emergence

If a question emerges while a change is `implemented` (a runtime
edge case discovered during RED→GREEN), the right move is :

1. Demote `.forge.yaml` `status` back to `planned` (or `designed`,
   depending on how deep the question runs).
2. Capture the question in `open-questions.md`.
3. Resolve it.
4. Re-promote through the pipeline.

Do **not** keep an `implemented` change with an open question — the
linter will fail the next CI run.

## Backwards compatibility

Pre-F.1 changes (those archived before this convention landed) do
NOT have `open-questions.md`. The Open Questions Gate treats
absence-of-file as zero-questions, so no historical change gets
retroactively flagged.

## See also

- Standard : [`global/open-questions.md`](../.forge/standards/global/open-questions.md)
- Article III.4 of the [Forge Constitution](../.forge/constitution.md)
- Change : [`f1-open-questions/`](../.forge/changes/f1-open-questions/)
