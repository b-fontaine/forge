# Specs — `b3-1-schema`

**Namespace** : `FR-B31-*`, `NFR-B31-*`, `ADR-B31-*`.

---

## Functional Requirements

### FR-B31-001 — the schema exists and identifies itself
`.forge/schemas/rust-cli-tui/1.0.0.yaml`, `name: rust-cli-tui`, `version: "1.0.0"`.
The validator derives the expected version from the filename and rejects a mismatch.

### FR-B31-002 — candidate, not scaffoldable, and the two agree
`stage: candidate` with `scaffoldable: false`. Asserted as a **pair**: the validator
rejects `candidate` + `scaffoldable: true`, and a half-flip is the failure `b9-11`
existed to prevent.

### FR-B31-003 — `layer_profile: client-only`
A CLI binary has no backend and no infra surface. Declaring stub layers to satisfy the
`multi-layer` triple would be fabrication under Article III.4 (`ADR-B31-002`).

### FR-B31-004 — two layers, `cli` and `tui`
From the ratified taxonomy's own description (clap + ratatui). Each carries
`id`/`path`/`fr_id_prefix`/`primary_agent` — required of **both** profiles. Agents are
the ratified Rust sub-team: Vulcan for `cli`, Terminal for `tui`.

### FR-B31-005 — the tdd-rust chain, inline, with no `extends:`
Eight phases in order, and the review phase keeps all six Rust gates (`cargo_test`,
`coverage_rust`, `clippy_clean`, `cargo_audit`, `zero_unwrap`,
`zero_unsafe_undocumented`).

### FR-B31-006 — no resolved version pin
Checked on a comment-stripped stream: the header legitimately discusses versions, and an
unstripped grep would read that discussion as the violation.

### FR-B31-007 — every component has an owner
Each declares its owning standard **or** a `delivered_by` naming a B.3.x brick. A
component with neither is a promise nobody owns. The set covers B.3's stated surface:
clap, ratatui, cargo-dist, code-signing, sbom, distribution-channels.

### FR-B31-008 — the header states the stage, the promotion path, and the inference
Including that the plan defers to a `B.3.1 → B.3.14` list this repository does not
contain.

### FR-B31-009 — the live validator passes it
`validate-foundations.sh`, not a re-implementation of its rules.

### FR-B31-010 — CHANGELOG and CI registration

---

## Non-Functional Requirements

### NFR-B31-001 — no shipped archetype is touched
The three stable schemas stay stable; the taxonomy enum is unedited.

### NFR-B31-002 — no dispatch key
It flips `forge init` from exit 2 to exit 3 and makes `t5-1` FR-T51-055 demand a trust
fixture. Both belong to the template brick.

### NFR-B31-003 — guards mutation-proven, needles unique in their region

---

## ADRs

### ADR-B31-001 — B.3.1 is the schema, by precedent

**Context.** B.3's fourteen-item breakdown is not in this repository.

**Decision.** Start with the schema, and say in the schema that this is inferred.

**Rationale.** B.6.1, B.7.1 and B.9.1 are each their archetype's schema — three for
three. The schema is also the only B.3 artefact with no upstream dependency: templates
need it, the dispatch key needs templates, the promotion needs a harness over all of
them.

**Consequence.** Every `delivered_by` pointer below names an inferred brick number. If
the real breakdown differs, those pointers move — which is cheap, and cheaper than
inventing a plan and presenting it as one.

### ADR-B31-002 — `client-only`, and the name is wrong

**Context.** `layer_profile` accepts `multi-layer` or `client-only`. A devtool is
neither, in the ordinary sense of the words.

**Decision.** `client-only`.

**Rationale.** What the discriminator actually answers is binary — *does the
{backend, frontend, infra} triple apply?* — and for a CLI it does not. Adding a third
value with identical behaviour would be taxonomy inflation; renaming the existing one
would touch `mobile-pwa-first`'s shipped schema, the validator and three harnesses, for
cosmetics.

**Consequence.** A reader meets `layer_profile: client-only` on a devtool and has to be
told why. The schema tells them, in place. Recorded as Q-001.
