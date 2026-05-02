# Standard: Open Questions Tracking

<!-- Audit: F.1 (f1-open-questions, FR-OQ-001) -->

This standard mechanises **Article III.4** of the Forge Constitution
(Anti-Hallucination Protocol). The Constitution requires the marker
`[NEEDS CLARIFICATION: ...]` whenever an agent or contributor cannot
resolve an ambiguity. This standard adds the **structural follow-up**:
a per-change `open-questions.md` file that tracks question lifecycle,
plus gates in `verify.sh` and `constitution-linter.sh` that prevent
archival or implementation while questions remain unresolved.

Activated by `.forge/standards/index.yml` triggers on terms
`open-questions`, `NEEDS CLARIFICATION`, `Q-001`, `clarification`,
`anti-hallucination`, `Article III.4`.

---

## Purpose

The marker `[NEEDS CLARIFICATION: <question>]` inline in `specs.md` /
`design.md` / `tasks.md` signals an unresolved ambiguity. But inline
markers alone are insufficient :

- **No inventory** of how many questions a change has, or how long
  they have been open.
- **No lifecycle** (open → in-discussion → answered → wontfix).
- **No mechanical block** preventing archive of a change with
  unresolved questions.
- **No audit trail** : a resolved question loses its provenance once
  the inline marker is replaced.
- **No transverse view** : "show me every open question across the
  project" requires manual greps.

The `open-questions.md` file fixes all five gaps.

---

## File Location and Lifecycle

For a change `<name>`, the open-questions file MUST live at :

```
.forge/changes/<name>/open-questions.md
```

No alternative locations are accepted (no centralised file, no
sub-directory, no different name).

**Lifecycle :**

1. **Created at `/forge:propose`** — the skill scaffolds an empty
   stub from `.forge/templates/open-questions.md.tmpl`. If the skill
   cannot be modified in the runtime environment, the maintainer or
   agent MUST create the stub manually at the same time as
   `proposal.md`.
2. **Populated as ambiguities surface** during `/forge:specify`,
   `/forge:design`, `/forge:plan`, or `/forge:implement`. Each new
   question gets a fresh `Q-NNN` block.
3. **Resolved before archive** — every question MUST be flipped to
   `answered` or `wontfix` and given a `### Resolution` block before
   `/forge:archive` runs. The `verify.sh` Open Questions Gate
   enforces this.
4. **Preserved indefinitely** — resolved questions are NEVER
   deleted. They form the audit trail of the change's decision
   history.

---

## Question Schema

Every question MUST be expressed as an H2 block in this exact shape :

```markdown
## Q-001: Short title (≤ 80 chars)

- **Status**: open | answered | wontfix
- **Raised in**: <file or section anchor>
- **Raised on**: YYYY-MM-DD
- **Raised by**: <agent or human handle>
- **Reference**: <optional, file:line>

### Question

<Full question text. May span multiple paragraphs. SHOULD reference
the corresponding `[NEEDS CLARIFICATION:]` marker by location.>

### Resolution

<Only present when Status != open. Schema below.>
```

The H2 title MUST match the regex `^## (Q-[0-9]{3}): .+$`.

**Q-NNN format** : `Q-` + zero-padded 3 digits (`Q-001`, `Q-002`,
..., up to `Q-999`). Numbering is **sequential per change**, never
reused even if a question is wontfix-ed. To find the next free
identifier, look at the highest Q-NNN already present in
`open-questions.md` and increment by 1.

---

## Status Enum

Status MUST be one of three values exactly :

| Status      | Meaning                                                                |
| ----------- | ---------------------------------------------------------------------- |
| `open`      | The question has been raised but not resolved. Default initial state. |
| `answered`  | A decision was made and recorded in the `### Resolution` block.       |
| `wontfix`   | The question is explicitly left without an answer for this change. The `### Resolution` block records the rationale (often "deferred to <future change>"). |

No other values (`in-progress`, `wip`, `deferred`, `blocked`) are
accepted. The Constitution-linter MUST flag invalid statuses.

---

## Resolution Block

When Status is `answered` or `wontfix`, an `### Resolution`
sub-section MUST follow the `### Question` block, with these fields :

```markdown
### Resolution

- **Resolved on**: YYYY-MM-DD
- **Resolved by**: <handle>
- **Decision**: <the answer chosen>
- **Rationale**: <why this answer ; trade-offs evaluated>
- **Resolved in**: <file/section where the resolution landed>
```

**The `Resolved in` field SHOULD point to the concrete location**
where the decision is now reflected in the codebase (e.g.
`proposal.md § "Décisions ouvertes — résolues" #Q-001` or
`specs.md § FR-OQ-005`). This makes the audit trail bidirectional.

---

## Verify Gate

`.forge/scripts/verify.sh` includes a section `── Open Questions Gate ──`
that scans `.forge/changes/*/open-questions.md` :

- **For each change**, read `.forge/changes/<name>/.forge.yaml`.
- If `status == archived` AND `open-questions.md` exists AND it
  contains at least one question with `Status: open`, emit a FAIL
  with format `FAIL: <change> has N open question(s) but is
  archived` and increment the FAIL counter.
- If `open-questions.md` is **absent**, the change is treated as
  having zero questions (backwards-compatible with all
  pre-F.1-archived changes).
- Skip-guard : the gate honours `is_under_examples` (FR-GL-026), so
  it never recurses into `examples/<example>/.forge/changes/`.

The gate runs in addition to existing sections ; it does NOT alter
their behaviour.

---

## Linter Rule

`.forge/scripts/constitution-linter.sh` includes a rule that
enforces "no `[NEEDS CLARIFICATION:` inline in `implemented` or
`archived` changes" :

- **For each change**, read `.forge/changes/<name>/.forge.yaml`.
- If `status` is `implemented` OR `archived`, scan
  `proposal.md / specs.md / design.md / tasks.md` (NOT
  `open-questions.md`, which is the legitimate location for the
  marker via the `### Question` body).
- Emit `FAIL <change>:<file>:<line>: NEEDS CLARIFICATION inline
  detected` for each occurrence.

The rule does NOT apply to `proposed`, `specified`, `designed`, or
`planned` statuses — questions in flight are normal during these
phases. The signal is "if you wrote code, you have no business
having unresolved questions inline".

When this rule fails on an in-flight change, the resolution path
is :

1. Identify the open question.
2. Add a corresponding `Q-NNN` block in `open-questions.md` (if not
   already there).
3. Resolve it (flip Status, write `### Resolution`).
4. Replace the inline `[NEEDS CLARIFICATION:]` marker in the
   `*.md` file with the resolved text or a reference to the
   `Q-NNN`.

If you can't resolve immediately, **demote the change status** to
`planned` (or earlier) until you can. Do NOT bypass the linter.

---

## Discovery

`bin/forge-questions.sh` aggregates open questions across all
changes :

```bash
# Default: list every Status: open question, sorted by Raised on.
bash bin/forge-questions.sh

# Filter by change name.
bash bin/forge-questions.sh --change f1-open-questions

# Filter by status.
bash bin/forge-questions.sh --status answered
```

Output is one question per line, format
`<change>:Q-NNN  <Title>  (raised <date> by <handle>)`.

The script reads `FORGE_ROOT` (default = current dir's `.forge/`
parent), so it can be invoked from anywhere within the project tree
or against a fixture in tests.

---

## Interdictions

**Interdiction 1 — Modify an `answered` question's `### Resolution`
block.**

Once a question is resolved, the `### Resolution` block is
**immutable history**. Any new information that would alter the
decision MUST be raised as a NEW question (`Q-NNN+1`) referencing
the previous one. Why : the audit trail loses its value if past
decisions can be silently rewritten.

**Interdiction 2 — Reuse a `Q-NNN` after deletion or wontfix.**

If a question turns out to be invalid (mistaken capture, duplicate),
do NOT delete its `Q-NNN` block. Flip its Status to `wontfix` with
rationale "deleted ; mistaken capture". Q-IDs are sequential per
change, **never reused** even when annulled. Why : preserves a
contiguous numbering and avoids confusion in cross-references.

**Interdiction 3 — Leave `[NEEDS CLARIFICATION:]` inline in
`implemented` or `archived` changes.**

The marker is legitimate only in the early lifecycle phases
(`proposed` through `planned`). Once code has been written
(`implemented`) or the change is sealed (`archived`), every
question MUST be resolved and the inline marker replaced. The
constitution-linter enforces this rule. Why : a change with code
AND open questions inline is a sign of process breakdown — code
shouldn't have been written before the ambiguity was lifted.
