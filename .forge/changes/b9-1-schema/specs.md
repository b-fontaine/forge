# Specifications: b9-1-schema

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.9.1 (docs/new-archetypes-plan.md §5.2 — mobile-pwa-first/2.0.0 archetype scaffold schema) -->

**Namespace** : `FR-B9-1-*` / `NFR-B9-1-*` / `ADR-B9-1-*`.
**Constitution** : v2.0.0, unchanged. This change authors the requirements + ADRs
for the `mobile-pwa-first / 2.0.0` **candidate** archetype scaffold schema. It ships
**no scaffolder, no template, no version pin**, and edits **no existing
schema/standard** — with one explicitly gated exception under Q-001 (a possible
narrow, backward-compatible relaxation of the B.8.3.b validator, which `/forge:design`
must ratify before any implementation). The schema file + harness are built at the
impl phase; `web-pwa/` templates arrive in B.9.2.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination),
IV (delta-based / additive), VI (Flutter architecture — `flutter_bloc` exclusivity,
CI-enforced since B.8.11), IX (observability), X.1 (80 % coverage).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §5.1–§5.2 (B.9.1 `mobile-pwa-first/2.0.0.yaml`, `mobile-only / 1.0.0` stays alias, effort S), §11 (T8) |
| **Sibling precedent** | `.forge/changes/b6-1-schema/` + `.forge/changes/b7-1-schema/` — the shape + rigor this change mirrors |
| **Target §** | `docs/ARCHITECTURE-TARGET.md` §6.3 — installable PWA on Android + desktop, native iOS fallback when push is critical |
| **Predecessor archetype (observed)** | `.forge/schemas/mobile-only/schema.yaml` — a **third** shape: `archetype:` / `schema_version:` keys, single layer `app` at `.`, **no `stage` / `scaffoldable` / `phases`**. Invisible to the versioned validator (glob `[0-9]*.[0-9]*.[0-9]*.yaml`, `validate-foundations.sh:407`). |
| **Versioned validator (observed)** | `check_versioned_schema_siblings` (`validate-foundations.sh:397-458`, B.8.3.b) — enforces `name`==dir, `version`==filename stem + SemVer, `layers` ⊇ **{backend, frontend, infra}** (`:436-438`), each with `id`/`path`/`fr_id_prefix`/`primary_agent`, `stage` ∈ {draft,candidate,stable}, **candidate ⇒ `scaffoldable: false`** (`:453`), `phases` non-empty. **Gates this file on landing.** |
| **The conflict (observed)** | `mobile-only` is verbatim *"No backend, no infrastructure, no BaaS"*. Two of the three required layer ids would be **fiction** for this archetype. → Q-001 / ADR-B9-1-001. Strictly harder than B.6.1's ADR-B6-1-004 case. |
| **Taxonomy pre-wiring (observed)** | `archetype.schema.json` v2 enum already contains `mobile-pwa-first` **and** `mobile-only` (deprecated legacy alias). `dispatch-table.yml:59-64` already carries `status: legacy_alias`, `target: mobile-pwa-first`, `migration: "B.9 (T8) — bin/forge-migrate-mobile-pwa.sh"`. **No taxonomy edit needed.** |
| **CLI selection (observed)** | `selectScaffoldableVersion` (`cli/src/domain/schema-version.ts`) picks the highest `stable` + `scaffoldable: true`; candidate-only ⇒ `null`. **CORRECTED 2026-07-27 (independent review, F1)**: T.4 did NOT add a `mobile-pwa-first:` key — only `status`/`target`/`migration` fields *under the `mobile-only:` key*. `init.ts:210-217` therefore refuses at the **dispatch gate with exit 2**, never reaching `selectScaffoldableVersion`. Verified live; the original "exit 3" was an unverified assumption marked as observed. Same trap B.7.1 hit — see `b7-2a-dispatch-register/proposal.md:10-16`. |
| **Flutter process phases (observed)** | `tdd-flutter/schema.yaml`: proposal → specs (Clio) → features (Spartan) → design (Athena) → tasks (Athena) → implementation (Hera) → review → archive; `flutter_specifics` block; `golden_tests_required: true`. |
| **Qwik precedent (observed)** | B.8.9 shipped `full-stack-monorepo/2.0.0/frontend/web-public/` (Qwik City + Connect-ES v2) + role-named standard `web-frontend.yaml` v1.0.0 (default `qwik-city`, alt `sveltekit`). **ABSENT** from it: Service Worker, Web Push/VAPID, `manifest.json`, offline shell → B.9.2 (gap, ADR-B9-1-005). |
| **B.9.6 status (observed)** | NSMA linter already activated repo-wide by B.8.11 (`state-management.yaml` `ci_blocking: true`). B.9.6 is a **no-op**; plan §5.2 already says so. |
| **Downstream gated by this** | B.9.2 … B.9.11 (all remaining B.9 bricks) |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Schema identity & shape (FR-B9-1-001 → 006)

##### FR-B9-1-001 — archetype-scaffold-schema shape (not the legacy `mobile-only` shape)
The file, when authored, MUST use the archetype scaffold schema top-level key set
(parity with `ai-native-rag/1.0.0.yaml` / `event-driven-eu/1.0.0.yaml`): `name`,
`version`, `stage`, `scaffoldable`, `description`, `tdd_enforced`,
`bdd_required_for_user_facing`, `coverage_threshold`, `layers`, `phases`. It MUST
NOT reuse the `archetype:` / `schema_version:` keys of `mobile-only/schema.yaml`.

##### FR-B9-1-002 — identity fields + filename↔version invariant
MUST declare `name: mobile-pwa-first`, `version: "2.0.0"`, `stage: candidate`. The
file MUST be `.forge/schemas/mobile-pwa-first/2.0.0.yaml` so the B.8.3.b
`name`==dirname and filename↔version invariants hold.

##### FR-B9-1-003 — non-scaffoldable candidate
MUST declare `scaffoldable: false` (B.8.3.b enforces candidate ⇒ `scaffoldable: false`).
Consequence (NFR-B9-1-002): `forge init --archetype mobile-pwa-first` refuses cleanly
with **exit 2** (dispatch gate) — never a broken scaffold. See the CLI-selection row above.

##### FR-B9-1-004 — TDD/BDD/coverage flags
MUST carry `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
`coverage_threshold: 80` (Articles I, II, X.1 not relaxed).

##### FR-B9-1-005 — candidate header block
MUST carry a header comment block stating: what `candidate` means while no `web-pwa/`
templates exist, the promotion trigger to `stable` + `scaffoldable: true` (the B.9.11
harness brick, mirroring B.6.7 / B.7.6 / B.8.14 — ADR-B9-1-002), and that the file is
additive.

##### FR-B9-1-006 — golden-test flag carried forward
MUST carry the Flutter golden-test obligation forward from `tdd-flutter`
(`golden_tests_required: true` or its scaffold-schema equivalent), since the native
surface keeps producing custom widgets.

#### Cluster 2 — Layers & the backend-less conflict (FR-B9-1-010 → 014)

##### FR-B9-1-010 — the two real surfaces MUST both be modelled
The schema MUST declare, as first-class layers, (a) the **native Flutter app**
surface inherited from `mobile-only` and (b) the **Qwik `web-pwa/`** channel added by
B.9.2. Each MUST carry `id` / `path` / `fr_id_prefix` / `primary_agent` per the
B.8.3.b per-layer contract.

##### FR-B9-1-011 — primary agents per surface
The native surface MUST name **Hera** as `primary_agent`; the `web-pwa` surface MUST
name **Iris-Web** (K.4, archived 2026-07-10, declared forward-stable for this
archetype). No agent file is created or edited by this change.

##### FR-B9-1-012 — no fabricated layer MAY scaffold nothing
The schema MUST NOT declare a layer id whose `path` corresponds to no scaffolded
surface in the B.9.2 template tree. Any layer present MUST be real. **This
requirement is what makes Q-001 blocking** — it is deliberately in tension with the
validator's `{backend, frontend, infra}` invariant, and `/forge:design` MUST resolve
that tension explicitly (ADR-B9-1-001) rather than silently satisfying one at the
other's expense.

##### FR-B9-1-013 — validator conformance on landing
Whatever ADR-B9-1-001 decides, the file as landed MUST make
`bash .forge/scripts/validate-foundations.sh` exit PASS with no new KO line, and
MUST NOT regress `verify.sh` or `constitution-linter.sh`.

##### FR-B9-1-014 — relaxation, if chosen, MUST be backward-compatible by default
If ADR-B9-1-001 selects the validator-relaxation option, the new discriminator (e.g.
`layer_profile:`) MUST default to today's enforced behaviour, so that **every existing
versioned schema keeps its current meaning with no edit** (`full-stack-monorepo/2.0.0`,
`ai-native-rag/1.0.0`, `event-driven-eu/1.0.0`). The sibling-harness cascade
(`b8-3b.test.sh` and any suite asserting the current KO string) MUST be enumerated in
`design.md` before implementation.

#### Cluster 3 — Phases & the PWA channel process (FR-B9-1-020 → 023)

##### FR-B9-1-020 — phases inlined, never `extends:`
The phases MUST be **inlined** (materialised from `tdd-flutter/schema.yaml`), NOT
declared via `extends:`. Re-confirmed ground truth: no scaffold-schema loader resolves
`extends` — `parseSchemaMeta` reads only version/stage/scaffoldable, and
`check_versioned_schema_siblings` reads `phases` from the file itself, so an
`extends: tdd-flutter` would fail `phases missing or empty`.

##### FR-B9-1-021 — the Flutter TDD phase chain MUST be preserved
The inlined chain MUST preserve proposal → specs → features → design → tasks →
implementation → review → archive, including the `features`-before-design BDD gate.

##### FR-B9-1-022 — channel-decision gate
The schema MUST carry a B.9-specific gate covering the PWA-vs-native channel choice
(ARCH §6.3: PWA for Web|Android, native iOS fallback when push is critical). Whether
this is a distinct `phase` or a constraint attached to `design` is ADR-B9-1-003. The
prose decision tree itself belongs to B.9.4 and MUST NOT be authored here.

##### FR-B9-1-023 — `pwa_specifics` block
The schema MUST carry a `pwa_specifics` (or equivalently named) block recording the
channel invariants: installability, offline shell, Web Push/VAPID, and the iOS
fallback rule — as **contract text, not pins**.

#### Cluster 4 — Component set, reference-only (FR-B9-1-030 → 032)

##### FR-B9-1-030 — reference-only components, zero inline pins
Components MUST be declared by reference to their owning standard, never with inline
versions (ADR-B8-3-002 / ADR-B7-1-003 / ADR-B6-1-003 precedent): Qwik →
`web-frontend.yaml`, OIDC → `identity.yaml`, observability → `observability.yaml`.

##### FR-B9-1-031 — deferred-standard gap recorded, never fabricated
Service Worker, Web Push (VAPID), `manifest.json` and the offline shell have **no
standard today**. They MUST be referenced as `delivered_by: B.9.2` with no inline pin
and no invented standard name.

##### FR-B9-1-032 — `flutter_bloc` exclusivity consumed as-is
The schema MUST NOT restate or relax Article VI.3; NSMA enforcement is already
CI-blocking since B.8.11 and is not this change's to touch.

#### Cluster 5 — Legacy alias preservation (FR-B9-1-040 → 042)

##### FR-B9-1-040 — `mobile-only / 1.0.0` untouched
This change MUST NOT edit `.forge/schemas/mobile-only/schema.yaml`,
`bin/forge-init-mobile-only.sh`, or `.forge/templates/archetypes/mobile-only/**`.
v0.3.0 adopters keep scaffolding a byte-equivalent tree.

##### FR-B9-1-041 — dispatch table untouched
This change MUST NOT edit `dispatch-table.yml`. Registering `mobile-pwa-first` as a
scaffoldable entry is B.9.2/B.9.11 territory; the alias metadata T.4 already wrote is
sufficient for the clean exit-2 refusal path; registering a `mobile-pwa-first:` key (which would move it to exit 3) is B.9.2/B.9.11 territory.

##### FR-B9-1-042 — forward mapping recorded for B.9.9
`design.md` MUST record how `mobile-only`'s single `app` layer maps onto the layer
model chosen by ADR-B9-1-004, because `bin/forge-migrate-mobile-pwa.sh` (B.9.9) will
have to honour that mapping. Recording only — no script here.

### Non-Functional Requirements

##### NFR-B9-1-001 — additive by default
Apart from the new `.forge/schemas/mobile-pwa-first/2.0.0.yaml` (and, only if Q-001
selects it, the backward-compatible validator discriminator), this change MUST create
no file outside `.forge/changes/b9-1-schema/` and `.forge/scripts/tests/b9-1.test.sh`.

##### NFR-B9-1-002 — clean refusal, never a broken scaffold
`forge init --archetype mobile-pwa-first` MUST refuse cleanly with an actionable
message and render nothing while the schema is candidate. The code is **2** (dispatch
gate) until a later brick registers a dispatch key, at which point it becomes 3.
Asserted by `b9-1.test.sh` T-L2-001 (L2, `FORGE_B9_1_LIVE=1`).

##### NFR-B9-1-003 — zero regression on the existing gates
`verify.sh` (currently 564 PASS / 0 FAIL) and `constitution-linter.sh` (currently
OVERALL PASS) MUST show no new FAIL. The `forge-ci.yml` line budget MUST be respected
in lockstep if a harness entry is added (current ceiling 420, set by B.6.8).

##### NFR-B9-1-004 — harness level split
`b9-1.test.sh` MUST provide L1 static assertions (schema shape, identity, layers,
phases, refusal path) with no Docker/network dependency; any live leg MUST be L2
opt-in behind an env flag, per the b6/b7/b8 harness convention.

##### NFR-B9-1-005 — no pin resolved at spec time
No component version may be resolved or committed before `/forge:implement`
(verify-then-pin, Article III.4; the T5.3.2 / b8-coroot lesson).

---

## ADRs (seeded — resolved at `/forge:design`)

| ADR | Question | Lean |
|-----|----------|------|
| **ADR-B9-1-001** | How a backend-less archetype satisfies `{backend, frontend, infra}`: (a) stub layers, (b) narrow validator relaxation via a defaulted `layer_profile:`, (c) stay out of the versioned family | **(b)** — (a) violates FR-B9-1-012 and poisons downstream bricks with dead layer ids; (c) forfeits the versioned routing B.9.8/B.9.11 need. **Blocking, maintainer call.** |
| **ADR-B9-1-002** | Stage/scaffoldable for the first cut + promotion owner | `candidate` + `scaffoldable: false`; promotion at B.9.11 |
| **ADR-B9-1-003** | Channel decision as a `phase` gate vs a `design` constraint | one `channel-decision` gate; prose tree stays B.9.4's |
| **ADR-B9-1-004** | Layer identity + forward mapping of `mobile-only`'s single `app` layer | decide ids at design; record the mapping for B.9.9 |
| **ADR-B9-1-005** | Component references + deferred Service Worker / Web Push / VAPID gap | reference-only, `delivered_by: B.9.2` |

## Acceptance Criteria (for the impl phase, summarised)

1. `.forge/schemas/mobile-pwa-first/2.0.0.yaml` exists, satisfies every FR of
   Clusters 1–4, and passes `validate-foundations.sh` with no new KO.
2. `b9-1.test.sh` is GREEN at `--level 1`; any L2 leg is opt-in.
3. `verify.sh` and `constitution-linter.sh` show no new FAIL.
4. `forge init --archetype mobile-pwa-first` exits 2 and renders nothing (clean refusal).
5. `mobile-only / 1.0.0` scaffolds byte-equivalently to before (FR-B9-1-040).
6. If ADR-B9-1-001 chose relaxation: every pre-existing versioned schema validates
   unchanged, and the enumerated sibling harnesses are GREEN.
