# Spec: b8-validator-versioned-schema

<!-- Audit: B.8.3.b (b8-3b-validator-versioned-schema) -->
<!-- Source change : `.forge/changes/b8-3b-validator-versioned-schema/` (delta specs.md authoritative). -->

**Namespace** : `FR-B83B-*` / `NFR-B83B-*` / `ADR-B83B-*`.
**Constitution** : v1.1.0, unchanged. This change is **propose + specify only**.
It authors the requirements + ADRs for rewiring the three shared Forge
validators to **discover** versioned candidate schema files
(`<archetype>/<MAJOR.MINOR.PATCH>.yaml`) and **enforce** candidate semantics,
as a strict superset of today's single-`schema.yaml` behavior. It ships **no
validator code, no harness, and edits no schema** — those are delivered in the
design + implementation phases of this change.
**Governing articles** : I (TDD RED-first for the harness), III.1/III.2 (specs
before code), III.4 (Anti-Hallucination), IV (delta-based: the validators are
evolved additively, not rewritten).

## Overview

This spec makes the B.8.3 candidate `full-stack-monorepo/2.0.0.yaml` gate-visible
via `validate-foundations.sh`, `verify.sh`, and `constitution-linter.sh` by
rewiring those three shared validators to discover versioned schema siblings
(`<archetype>/<X.Y.Z>.yaml`) alongside the canonical `schema.yaml`. The rewiring
is generic (archetype dir name derived from path, SemVer-filename glob) and a
strict superset — every archetype with only a single `schema.yaml` and no
versioned sibling continues to pass exactly as before. New invariants enforced:
filename↔version agreement and `candidate ⇒ scaffoldable: false`. Scaffolder
guard (preventing `forge init` from materializing a non-scaffoldable schema) is
deferred to **B.8.14**; enforcement in B.8.3.b is validator-side only.

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Versioned-schema discovery (FR-B83B-001 → 010)

##### FR-B83B-001 — discover versioned siblings alongside `schema.yaml`
The validators MUST discover sibling schema files whose filename matches the
SemVer pattern `<MAJOR>.<MINOR>.<PATCH>.yaml` (e.g. `2.0.0.yaml`) in the same
archetype directory **alongside** the canonical `schema.yaml`. The canonical
`schema.yaml` MUST continue to be validated exactly as today; discovered
versioned siblings are validated **in addition**, not instead.

##### FR-B83B-002 — validate each versioned file with the same rule-set
Each discovered versioned file MUST be validated with the **same rules already
applied to `schema.yaml`** (`validate-foundations.sh:107-145`): mapping root;
`name == <archetype directory name>`; `version` matches the SemVer regex
`^\d+\.\d+\.\d+(-[\w.-]+)?$`; `layers` non-empty with ids ⊇
{backend, frontend, infra} and each layer carrying
`id/path/fr_id_prefix/primary_agent`; `stage ∈ {draft, candidate, stable}`;
`stage == stable ⇒ version ≥ 1.0.0` without prerelease; non-empty `phases`.

##### FR-B83B-003 — name MUST equal the archetype directory name
For a discovered file under `.forge/schemas/<archetype>/<X.Y.Z>.yaml`, the
validation MUST require `name == <archetype>` (the directory name) — generalizing
the existing hard-coded `name == 'full-stack-monorepo'` check so the same rule
holds for any archetype dir without a literal per-archetype constant.

##### FR-B83B-004 — discovery is a no-op where no versioned sibling exists
For any archetype directory containing **only** a single canonical schema file
and no `<X.Y.Z>.yaml` sibling, discovery MUST add **zero** new validations and
MUST NOT change the existing pass/fail outcome. (Six of seven archetype dirs are
in this state today — see NFR-B83B-001.)

#### Cluster 2 — New versioned-regime invariants (FR-B83B-010 → 020)

##### FR-B83B-010 — filename ↔ version invariant
A discovered versioned file named `X.Y.Z.yaml` MUST declare `version: "X.Y.Z"`
(the filename and the declared `version` MUST agree). A mismatch (e.g.
`2.0.0.yaml` declaring `version: "2.1.0"`) MUST fail the gate.

##### FR-B83B-011 — candidate invariant (`candidate ⇒ scaffoldable: false`)
Any schema (canonical or versioned) whose `stage` is `candidate` MUST carry a
top-level `scaffoldable: false`. A `candidate` schema missing the field, or
declaring `scaffoldable: true`, MUST fail the gate. (The live
`full-stack-monorepo/2.0.0.yaml` already declares `scaffoldable: false` and so
passes.)

##### FR-B83B-012 — `scaffoldable` NOT required on stable
A `stable` schema MUST NOT be required to carry `scaffoldable`. The frozen 1.0.0
`schema.yaml` (stage `stable`, **no** `scaffoldable` field) MUST keep validating
unchanged. The candidate invariant (FR-B83B-011) applies **only** to
`stage: candidate`; `draft` and `stable` are unaffected by it.

##### FR-B83B-013 — invariants enforced inside the per-file validation path
The filename↔version and candidate invariants MUST be enforced inside the same
per-file validation path that runs the SemVer/stage checks, so each discovered
versioned file is held to a **strict superset** of the `schema.yaml` rule-set —
not a separate, divergent check that could drift.

#### Cluster 3 — Shared-validator wiring (FR-B83B-020 → 030)

##### FR-B83B-020 — wire discovery into all three shared validators
Versioned-schema discovery MUST be wired into all three shared validators:
`validate-foundations.sh` (FR-GL-001 schema check), `verify.sh` (the Monorepo
Foundations section gated at `verify.sh:379`, plus `resolve_layer_path` at
`verify.sh:83`), and `constitution-linter.sh` (`resolve_monorepo_path` at
`constitution-linter.sh:69`). The literal `schema.yaml` path each currently uses
MUST be preserved as the canonical entry; discovery is additive.

##### FR-B83B-021 — preserve `verify.sh` aggregation contract
`verify.sh` aggregates `validate-foundations.sh`'s `PASS:`/`FAIL:` lines
(`verify.sh:385-391`). Any new versioned-file validations MUST emit through the
existing `pass_fr`/`fail_fr` (or `pass`/`fail`) channels so the aggregate
counters and exit code semantics are unchanged in shape (one PASS/FAIL line per
check). No new output format is introduced.

##### FR-B83B-022 — `resolve_layer_path` / `resolve_monorepo_path` unchanged for `schema.yaml`
The layer-path resolution helpers in `verify.sh` and `constitution-linter.sh`
MUST keep resolving layer paths from the canonical `schema.yaml` exactly as today
(they drive scoped Article VI/VII re-runs against `frontend/`, `backend/`). B.8.3.b
MUST NOT change which file these helpers resolve layer paths from — versioned
discovery is for **validation**, not for layer-path resolution.

#### Cluster 4 — Harness + CI registration (FR-B83B-030 → 040)

##### FR-B83B-030 — new harness asserting discovery + invariants + backward-compat
A new `b8-3b.test.sh` (or an explicit extension of `b8-3.test.sh`) MUST assert,
at minimum: (1) the versioned `2.0.0.yaml` is discovered and validated by the
rewired logic; (2) the filename↔version invariant (FR-B83B-010); (3) the
candidate invariant (FR-B83B-011) including the negative case (a `candidate`
without `scaffoldable: false` fails); (4) backward-compat — an archetype with only
a `schema.yaml` still passes (FR-B83B-004) and the frozen `schema.yaml` (stage
`stable`, no `scaffoldable`) still validates (FR-B83B-012). The harness MUST be
L1 (hermetic, ≤ 5 s, zero net/Docker), mirroring `b8-3.test.sh` conventions
(`--level` flag + `_helpers.sh`).

##### FR-B83B-031 — RED-first harness (Article I)
Per Constitution Article I, the harness MUST be committed and observed FAILING
(RED) before the validator rewiring exists, then turn GREEN after the rewiring is
authored. The RED witness is the gap between the harness commit and the
validator-rewiring commit.

##### FR-B83B-032 — one-line CI registration
The harness MUST be registered as a **single** entry appended to the declarative
`harnesses=( … )` bash array in `.github/workflows/forge-ci.yml` (lines 68-109),
adjacent to the existing `b8-3.test.sh --level 1` entry. No new CI job, no
per-harness step.

#### Cluster 5 — Scaffolder guard deferral + plan ratification (FR-B83B-040 → 050)

##### FR-B83B-040 — NO scaffolder code change (explicit non-goal)
B.8.3.b MUST NOT modify the scaffolder (`cli/src/commands/init.ts` or any
`init.sh`). The scaffolder dispatches by archetype name and cannot select a
versioned schema file today (observed: `init-archetype.ts` dispatches by archetype
name to a per-archetype wrapper script and reads no schema YAML; `cli.ts:213-226`
(`resolveFrameworkVersion`) hard-codes `"schema.yaml"`, never a versioned file). Enforcement of
non-scaffoldability in B.8.3.b is therefore the **validator invariant**
(FR-B83B-011), not a runtime guard.

##### FR-B83B-041 — runtime selection guard deferred to B.8.14
The spec MUST define that the **runtime selection guard** — preventing `forge
init` from materializing a non-scaffoldable (`scaffoldable: false`) schema — is
deferred to **B.8.14**, when 2.0.0 is promoted to `stable` and the scaffolder
gains versioned-schema selection. Until then, the only enforcement is the
validator invariant (ADR-B83B-004).

##### FR-B83B-042 — ratify B.8.3.b in the plan + roadmap
This change MUST be accompanied (in its implementation phase) by promoting
B.8.3.b in `docs/new-archetypes-plan.md` §4.2 from "Proposed — not yet committed"
(line 2267) to a committed brick, and reflecting it in the roadmap/status table.
This is the plan-ratification deliverable; it is a documentation edit, not a code
edit.

### Non-Functional Requirements

##### NFR-B83B-001 — backward compatibility is the dominant constraint (strict superset)
The rewiring MUST be a **strict superset** of today's behavior. Every archetype
that has only a single `schema.yaml` and no versioned sibling MUST keep passing
**exactly** as before (six of seven archetype dirs today), and the frozen
`full-stack-monorepo/schema.yaml` MUST keep validating byte-untouched. No
existing PASS may flip to FAIL as a result of discovery. This is the dominant
NFR because the three validators are **shared infrastructure that runs on the
framework repo AND on every scaffolded target project** — any regression has
repo-wide and downstream-project-wide blast radius.

##### NFR-B83B-002 — full CI matrix GREEN before flip/merge (sibling-harness coupling)
Because the validators are shared infra, the change MUST run the **full CI
matrix** (all harnesses + both gates) GREEN before the brick is flipped
`planned → implemented` or merged. Per the shared-standard/sibling-harness
coupling lesson, bumping shared infra without re-running ALL siblings rots CI
silently on `main`. Reviewer independence: the rewiring MUST be re-executed by an
independent reviewer (not trusted from the author's transcript).

##### NFR-B83B-003 — frozen 1.0.0 byte-identity preserved
`full-stack-monorepo/schema.yaml` and `full-stack-monorepo/1.0.0.tar.gz` MUST be
byte-unchanged by this change and its implementation (respects B.8.2 freeze + its
sha256 guard). `full-stack-monorepo/2.0.0.yaml` (the B.8.3 deliverable) MUST also
be byte-unchanged — B.8.3.b reads and validates it, never edits it.

##### NFR-B83B-004 — performance budget preserved
`validate-foundations.sh` MUST stay < 2 s (its NFR-002 budget) and the new
`b8-3b.test.sh` MUST stay L1 ≤ 5 s. Discovery is `python3` `yaml.safe_load` +
filesystem glob only — no network, no Docker, no subprocess chains.

##### NFR-B83B-005 — discovery is generic, not per-archetype hard-coded
The discovery + per-file validation MUST be expressed generically (archetype dir
name derived from path; SemVer-filename glob), NOT as a literal per-archetype
constant. This keeps it correct for future versioned candidates (plan §4.2 B.9.1
`mobile-pwa-first/2.0.0.yaml`) without further validator edits.

##### NFR-B83B-006 — anti-hallucination grounding
Every validator path, line number, and rule cited MUST be re-read from the live
scripts. Contradictions in upstream framing MUST be recorded, not normalized:
specifically, the b8-3 design's description of `validate-foundations.sh` ~271-281
as an "env.example check" is incorrect — that region is `check_multi_layer_change_metadata()`
(FR-GL-017, lines 269-354), a change-metadata check. The only env.example
reference, `verify.sh:571`, is unrelated to the schema path. Recorded
(Article III.4).
