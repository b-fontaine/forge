# Specs — `b9-4-archetype-decision-tree`

**Namespace** : `FR-B94-*`, `NFR-B94-*`, `ADR-B94-*`.

---

## Functional Requirements

### FR-B94-001 — the channel decision tree exists

`docs/ARCHETYPES.md` MUST carry a section documenting the `mobile-pwa-first` channel
decision: PWA as the default surface for Web, Android and desktop; the native Flutter
surface as the prescribed fallback when push delivery is critical on iOS.

It MUST name `pwa.yaml::channel_fallback` as the normative rule and the schema's
`channel-decision` phase as where the choice is recorded per change.

### FR-B94-002 — the tree states a routing rule, never a platform capability

The section MUST NOT assert that iOS cannot deliver Web Push, nor any iOS version
floor, nor any concrete Push API limitation. The repository establishes none of those
(see `evidence.md` P-1). It MUST reproduce the repo's own epistemic framing — iOS
installed-PWA push is *not assumed* — and MUST say that the routing rule makes no
claim about iOS capability in either direction.

### FR-B94-003 — the tree says what the archetype actually ships today

The section MUST state that `mobile-pwa-first / 2.0.0` is `stage: candidate` /
`scaffoldable: false`, that `forge init --archetype mobile-pwa-first` therefore exits
3, and that the reachable path today is `forge init --archetype mobile-only` followed
by `bin/forge-migrate-mobile-pwa.sh`.

It MUST also state that the archetype is `layer_profile: client-only` — two layers,
no backend and no infrastructure — because `ARCHITECTURE-TARGET §6.3`, which the
normative rule cites, diagrams a target with an Envoy gateway, a Rust BFF, Postgres
and Zitadel that fresh init does not produce.

### FR-B94-004 — `flutter-firebase`'s row stops advertising a removed archetype

The row MUST record that the archetype was removed from the taxonomy (`ADR-007`,
2026-05-04) rather than planned, and MUST point at the sanctioned alternative in the
row where a reader looks.

It MUST NOT claim the attempt produces a clean policy refusal: measured, it exits 127
with a shell error (see `NFR-B94-002`).

### FR-B94-005 — `mobile-only`'s row discloses the rename

The row MUST disclose `status: legacy_alias` / `target: mobile-pwa-first` and name the
migration driver, while remaining accurate that the archetype still scaffolds. It MUST
NOT be marked simply "Deprecated": the successor is not yet scaffoldable, so a reader
steered off `mobile-only` today has nowhere to go.

### FR-B94-006 — the flagship Stack cell stops naming what fresh init does not ship

Two claims in that cell are false for `forge init` as it renders today:

- **Kong.** `scaffold-plan-2.0.0.yaml` contains zero `kong` occurrences; the same
  document says so 9 lines later (*"the 2.0.0 tree (Kong-less, Envoy Gateway)"*).
- **"Temporal → DBOS swap is the breaking change of B.8."** Cancelled for Rust by
  `ADR-B8O-001` (2026-06-01, no Rust SDK); DBOS is a watch-list `future-option` and
  appears nowhere in `.forge/templates/`.

### FR-B94-007 — the matrix guard is derived, not a frozen list

`b5.test.sh`'s FR-IW-009 guard MUST assert against the **table rows**, not the whole
document, and the expected archetype set MUST be **derived from
`.forge/scaffolding/dispatch-table.yml`** rather than hardcoded.

Derivation rule: every dispatch-table archetype with a real scaffolder and a status
other than `candidate` or `removed_from_roadmap` MUST have a table row. Candidates are
excluded deliberately — that is the precedent (`ai-native-rag` and `event-driven-eu`
each got their row after promotion, never while candidate), and it is what makes the
guard demand a `mobile-pwa-first` row **automatically** the moment B.9.11 flips the
status.

The names `FR-IW-009` mandates verbatim (`b5-1-init-wizard/specs.md:252`) MUST still
be asserted, scoped to table rows. `rust-cli-tui`'s row is spec-mandated and MUST NOT
be touched.

### FR-B94-008 — CHANGELOG and resync

`[Unreleased]` entry; plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md`, both
files.

---

## Non-Functional Requirements

### NFR-B94-001 — no claim survives that a probe did not establish

Every factual statement added to `docs/ARCHETYPES.md` traces to a measurement recorded
in this change's `evidence.md`. Where the repository is silent — the iOS constraint —
the section says the repository is silent.

### NFR-B94-002 — the guards are scoped and mutation-proven

The matrix guard MUST fail when any protected row is deleted, proven by deleting each
row in turn and re-running CI's own invocation. It MUST carry anti-vacuity floors on
both the derived set size and the row count. This is `b9-10`'s `T-029` lesson applied
one file over.

### NFR-B94-003 — no deliverable outside documentation and harnesses

Zero changes to `cli/`, `bin/`, `.forge/templates/`, `.forge/schemas/`,
`.forge/scaffolding/`, `.forge/specs/`, `docs/ARCHITECTURE-TARGET.md`.

---

## ADRs

### ADR-B94-001 — no `mobile-pwa-first` row until B.9.11

**Context.** The brick documents a decision about an archetype absent from the matrix.

**Decision.** Write the decision-tree section; add no table row. Let the derived guard
demand the row automatically when the promotion flips the status.

**Rationale.** `forge init --archetype mobile-pwa-first` exits 3 today. A matrix row is
an availability statement, and the column's other values (`Active`,
`Planned (B.2)`) are availability states. Advertising a candidate as pickable repeats
`flutter-firebase`'s defect with the sign reversed. Precedent agrees: no archetype has
held a row while candidate.

**Consequence.** The archetype is named in the document — in `mobile-only`'s successor
disclosure and in the decision-tree section — without being offered. B.9.11 gains a
task it cannot skip, because the guard turns red the moment it flips the status
without adding the row.

### ADR-B94-002 — document the rule, record the missing basis

**Context.** The repo routes push-critical iOS to native on the authority of one
external blog link.

**Decision.** State the routing rule with its sources; state explicitly that the
underlying platform constraint is not established in-repo; open a question.

**Rationale.** Writing *"iOS cannot do Web Push"* would invent a claim the repo never
made and that stopped being true at Safari 16.4. Writing nothing leaves adopters
guessing why a whole native surface exists. Article III.4: say what is known, name
what is not.

**Consequence.** An adopter can decide whether the constraint still binds *their*
iOS floor. The alternative — an unsourced absolute — would have them carry a Flutter
surface on the strength of a 2026-04 blog post they were never shown.

### ADR-B94-003 — fix the guard where it lives

**Context.** The broken matrix guard is `b5.test.sh`'s; B.9 guards have been hosted in
`b9-2.test.sh` since B.9.9 because `forge-ci.yml` is at 419/420.

**Decision.** Repair FR-IW-009's guard **in `b5.test.sh`**; put only the
decision-tree content battery in `b9-2.test.sh`.

**Rationale.** FR-IW-009 owns the matrix; a second harness asserting the same table
from another file is how two sources of truth start. The line budget forbids a new
harness, not editing an existing one.

**Consequence.** `b5.test.sh` gains a `dispatch-table.yml` read it did not have.
Accepted: deriving from the registry is the whole point of FR-B94-007.
