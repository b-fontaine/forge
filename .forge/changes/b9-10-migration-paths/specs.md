# Specs — `b9-10-migration-paths`

**Namespace** : `FR-B910-*`, `NFR-B910-*`, `ADR-B910-*`.

---

## Functional Requirements

### FR-B910-001 — the cross-archetype section exists

`docs/MIGRATION-PATHS.md` MUST carry a section for
`mobile-only 1.0.0 → mobile-pwa-first 2.0.0`, naming
`bin/forge-migrate-mobile-pwa.sh` as its driver.

### FR-B910-002 — the section states the additive contract as a measurement

It MUST state **26 files added, 0 modified**, and that a migrated tree is
byte-identical to a native `forge init --archetype mobile-pwa-first` render except
`.forge/scaffold-manifest.yaml`. Both are `b9-9` measurements, not predictions ; the
document MUST NOT present `ADR-B9-1-004`'s prediction as the evidence.

### FR-B910-003 — the section documents the refusal envelope

The exit codes an adopter can hit MUST be tabulated: **0 / 2 / 5 / 7 / 8**, each with
the condition that produces it. Exit 7 (`web-pwa/` already present) and exit 8
(collision) are the two that describe deliberate refusals and MUST say so.

### FR-B910-004 — the section carries the `candidate` caveat

`mobile-pwa-first / 2.0.0` is `stage: candidate` / `scaffoldable: false` until B.9.11.
The section MUST say so and name B.9.11, so that a reader who runs the script
understands why `forge init` refuses the same archetype.

### FR-B910-005 — the index is complete, and stays complete

The document MUST open with an index table covering **every** migration Forge
supports, each row naming its driver and the document that owns its walkthrough.

A test MUST assert coverage mechanically: every `bin/forge-migrate-*.sh` in the
repository appears in `docs/MIGRATION-PATHS.md`. This is the guard that makes the
document's first sentence enforceable — the flagship's absence is exactly the drift it
catches.

### FR-B910-006 — the two documents state their boundary

`MIGRATION-PATHS.md` MUST state that `MIGRATIONS.md` owns same-archetype
version-to-version runbooks and that it itself owns cross-archetype paths.
`MIGRATIONS.md` MUST carry a reciprocal cross-reference so a reader landing on either
one can reach the other.

### FR-B910-007 — what `forge upgrade` will not do afterwards

The section MUST record that `.forge/framework-owned-paths.yml` names nothing under
`web-pwa/`, so framework-side changes to the Qwik surface do not propagate by
`forge upgrade` — and that this is inherited from the archetype, identical for a fresh
init, not introduced by the migration.

### FR-B910-008 — rollback is stated, because the script has none

Unlike `forge-migrate-flagship.sh`, the B.9.9 script has no `--rollback`. The section
MUST say what to remove by hand, and MUST NOT imply a flag that does not exist.

### FR-B910-009 — CHANGELOG

An `[Unreleased]` entry anchored on the change name.

---

## Non-Functional Requirements

### NFR-B910-001 — every stated fact is traceable to a probe

No figure, exit code or flag in the new section may be written from memory. Each comes
from `b9-9`'s `evidence.md` or from a probe recorded in this change's `evidence.md`.

### NFR-B910-002 — the document's claims track the code

A test MUST assert that the flags the section documents exist in the script's argument
parser and that every exit code it tabulates is reachable in the script's source.
Prose that drifts from the ABI is the failure mode this brick exists to fix.

### NFR-B910-003 — no deliverable outside documentation

Zero changes to `bin/`, `.forge/templates/`, `.forge/schemas/`,
`.forge/scaffolding/`. The only executable artefacts are harness guards.

### NFR-B910-004 — the existing sections stay byte-stable

The T.5 section is a shipped artefact referenced by
`constitution-linter.sh:1196`. Its content MUST NOT change ; only material above and
below it is added.

---

## ADRs

### ADR-B910-001 — index here, runbook where it already lives

**Context.** The flagship runbook is in `MIGRATIONS.md`. The claim to index everything
is in `MIGRATION-PATHS.md`. Two ways to reconcile: move the runbook, or index it where
it is.

**Decision.** Index it where it is. `MIGRATION-PATHS.md` gains a row and a link ; not
one line of the flagship runbook moves.

**Rationale.** `docs/MIGRATIONS.md` is asserted by `b8-10.test.sh::T-009` (five
content checks), `b8-12.test.sh::T-017/T-018`, and `b8-13`. It is cited by
`bin/forge-upgrade.sh`'s exit-7 abort as the document adopters are sent to. Moving its
content would be a large edit to a guarded, externally-referenced artefact in a brick
whose deliverable is one new section. Duplicating it would create two runbooks that
drift.

**Consequence.** A reader needs one hop to reach the flagship walkthrough. That is the
cost, and it is paid by a link in a table rather than by a divergence risk.

### ADR-B910-002 — the boundary is cross-archetype vs same-archetype

**Context.** With three migrations indexed, "which document?" needs an answer that a
fourth migration can apply without asking.

**Decision.** Same archetype, version to version → `MIGRATIONS.md`. Different
archetype → `MIGRATION-PATHS.md`.

**Rationale.** It is the split `.forge/specs/init-wizard.md:276` already assigned
(*"cross-archetype migration guide"*) and the one the existing content already
follows — it needed writing down, not inventing. It also tracks a real difference in
content: a same-archetype jump is a version runbook with phases and rollback ; a
cross-archetype jump is a question of what the target archetype has that the source
does not.

**Consequence.** The T.5 section is same-archetype and sits, by this rule, in the
wrong document. It is **not** moved: NFR-B910-004 freezes it, and
`constitution-linter.sh:1196` points a live WARN at it. The index row records the
anomaly rather than hiding it.

### ADR-B910-003 — record the `framework-owned-paths` gap, do not close it

**Context.** `web-pwa/` is outside `framework-owned-paths.yml` for both archetypes.

**Decision.** Document it in the section and open a question ; change no template.

**Rationale.** Closing it means editing a scaffolded template, which changes what every
future `forge upgrade` merges into adopter projects — a behavioural change needing its
own RED-first brick and a snapshot consequence. Doing that inside a documentation
brick is how an unreviewed template edit ships.

**Consequence.** Adopters are told the truth now ; the fix is scoped separately.
