# Specifications: b8-3-schema-candidate

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.3 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0, 2.0.0 candidate schema) -->

**Namespace** : `FR-B8-3-*` / `NFR-B8-3-*` / `ADR-B8-3-*`.
**Constitution** : v1.1.0, unchanged. This change is **propose + specify only**.
It authors the requirements + ADRs for the `full-stack-monorepo / 2.0.0`
**candidate** schema (the spec-of-the-target gating B.8.4–B.8.9). It ships **no
schema file, no template, no version pin, and edits no standard** — the schema
file and pins are delivered later (impl phase + B.8.4–B.8.7).
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination),
IV (delta-based: the candidate evolves, does not rewrite, `schema.yaml`).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.1 (additive-first/breaking-second), §4.2 B.8.3 (`2.0.0.yaml`, status `candidate`, effort M) |
| **Existing 1.0.0 schema (observed)** | `.forge/schemas/full-stack-monorepo/schema.yaml` — `name: full-stack-monorepo`, `version: "1.0.0"`, `stage: stable`, `layers[backend/frontend/infra]`, `fr_id_prefix_cross_layer: FR-GL-`, `cross_layer.agent: Janus`, `phases[proposal…archive]`; stage semantics (draft/candidate/stable) in the header (ADR-004) |
| **Validator path (observed)** | `validate-foundations.sh:92` (FR-GL-001), `verify.sh:83`, `constitution-linter.sh:69` all hard-code `…/full-stack-monorepo/schema.yaml` (literal filename, no glob). A `2.0.0.yaml` sibling is invisible to all gates today. |
| **Validator stage rules (observed)** | `validate-foundations.sh:132-139` — `stage` ∈ {draft, candidate, stable}; `stage == stable ⇒ version ≥ 1.0.0 without prerelease`. No rule for a `candidate` coexisting with a frozen `stable` sibling, no scaffoldability gate keyed on stage. |
| **Baseline reality (observed)** | `docs/B8-BASELINE.md` — Postgres **16**-alpine no pgvector (§2 delta to 17+pgvector); `fsm-backend` `image: scratch` placeholder (§3); gateway `kong:3.6` (§1); Temporal **doc-only, not deployed** (§4); obs trio SigNoz/Coroot 1.20.2/Beyla 3.15.0 closed (B.8.8) |
| **2.0.0 component standards (observed)** | `orchestration.yaml` v1.0.0 `default: dbos`/`fallback: temporal`; `persistence.yaml` v1.0.0 `default: postgres-17`/`extensions:[pgvector-0.8,postgis,timescaledb]`; `identity.yaml` v1.0.0 `default: zitadel`; `transport.yaml` v1.2.0 `protocol: connect-rpc`/`fallback: grpc-web` + `codegen.versions` pins |
| **Gateway pin (observed gap)** | No Envoy/gateway pin in any `*.yaml` standard. Only `infra/kong.md` (markdown) + `infra/kong` in `index.yml`. Envoy pin is delivered by B.8.4. |
| **Sibling/predecessors** | B.8.1 (`docs/B8-BASELINE.md`), B.8.2 (`b8-2-legacy-snapshot`, 1.0.0 freeze + reverse-target guard) |
| **Downstream gated by this** | B.8.4 (Envoy), B.8.5 (DBOS), B.8.6 (Connect), B.8.7 (Zitadel), B.8.9 (Qwik web-public), B.8.12 (zero-regression gate), B.8.14 (the actual 1.0.0→2.0.0 bump) |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Candidate schema identity & shape (FR-B8-3-001 → 010)

##### FR-B8-3-001 — schema evolves the existing shape (delta, not rewrite)
The 2.0.0 candidate schema, when authored in the impl phase, MUST reuse the
top-level key set of the existing `schema.yaml` (`name`,
`version`, `stage`, `description`, `tdd_enforced`,
`bdd_required_for_user_facing`, `coverage_threshold`, `layers`,
`fr_id_prefix_cross_layer`, `cross_layer`, `phases`) and evolve their values.
It MUST NOT introduce a divergent top-level structure (Article IV).

##### FR-B8-3-002 — identity fields
The schema MUST declare `name: full-stack-monorepo`, `version: "2.0.0"`,
`stage: candidate`. The version MUST satisfy the validator's SemVer regex.

##### FR-B8-3-003 — coverage / TDD / BDD flags preserved
`tdd_enforced: true`, `bdd_required_for_user_facing: true`, and
`coverage_threshold: 80` MUST be carried unchanged from 1.0.0 (Constitution
Articles I, II, X are not relaxed by the migration).

##### FR-B8-3-004 — must NOT edit the frozen 1.0.0 schema
The change (and the downstream schema-authoring step) MUST NOT modify
`.forge/schemas/full-stack-monorepo/schema.yaml`. The 1.0.0 surface is in
maintenance-freeze (B.8.2). The 2.0.0 candidate is a NEW sibling artifact
(ADR-B8-3-001). `git diff --name-only` MUST show `schema.yaml` untouched.

##### FR-B8-3-005 — candidate stage header block
The schema MUST carry a header block (mirroring the existing ADR-004 stage
semantics block) that states, for THIS 2.0.0 file: what `candidate` means while
a frozen `stable` 1.0.0 sibling exists, the promotion trigger to `stable`, and
that it is not scaffoldable by default (per ADR-B8-3-003).

#### Cluster 2 — 2.0.0 component SET & standard references (FR-B8-3-010 → 020)

##### FR-B8-3-010 — declare the component SET by name
The schema MUST declare the 2.0.0 component set by name: **Envoy Gateway**
(gateway), **DBOS embedded** (workflow orchestration), **Connect-RPC**
(transport), **Zitadel** (identity), **Postgres 17 + pgvector** (persistence),
**SigNoz + OBI + Coroot** (observability — already closed at B.8.8).

##### FR-B8-3-011 — reference source standards, do NOT inline pins
For each pinnable component the schema MUST reference its source standard rather
than inline a version number (ADR-B8-3-002, **decided reference-only 2026-05-30**):
DBOS → `orchestration.yaml`, Postgres/pgvector → `persistence.yaml`,
Zitadel → `identity.yaml`, Connect-RPC codegen → `transport.yaml`,
observability → `observability.yaml`. The schema MUST NOT re-pin any version
already owned by a standard.

##### FR-B8-3-012 — Envoy pin is deferred (no standard source today)
The schema MUST NOT invent an Envoy version pin. No `*.yaml` standard pins a
gateway today (only `infra/kong.md` markdown). The schema MUST reference the
gateway decision (Kong→Envoy) and record that the Envoy pin is **delivered by
B.8.4** (Article III.4 — never guess an external pin).

##### FR-B8-3-013 — Postgres 16→17 + pgvector recorded as a crossing delta
The schema MUST surface the Postgres 16→17 + pgvector delta (B8-BASELINE §2) as
an explicit migration-crossing delta, never a silent bump. The 2.0.0 target is
`postgres-17` + `pgvector-0.8` per `persistence.yaml`; the schema records this
is a delta the migration crosses (B.8.5 DBOS state tables + B.7 RAG depend on
it).

#### Cluster 3 — Layer topology (FR-B8-3-020 → 030)

##### FR-B8-3-020 — preserve the minimum layer triple
The schema MUST keep at least `backend`, `frontend`, `infra` layers, each with
`id`, `path`, `fr_id_prefix`, `primary_agent` (validator FR-GL-001 requires
this triple). `fr_id_prefix_cross_layer: FR-GL-` MUST be preserved.

##### FR-B8-3-021 — model the web-public / web-backoffice split
The schema MUST model the 2.0.0 web split per plan §4.2 B.8.9: a Qwik
`web-public/` surface and a Flutter Web `web-backoffice/` surface, with Janus
arbitrating both. Whether these are new `layers[]` entries or sub-paths under
`frontend` is decided by ADR-B8-3-004. The chosen modeling MUST keep the
validator's required `backend/frontend/infra` triple satisfied.

##### FR-B8-3-022 — preserve cross-layer Janus routing
`cross_layer.agent: Janus` and its `triggers` (`layers_count_ge: 2`) MUST be
preserved/evolved consistently with any new layer added by FR-B8-3-021.

#### Cluster 4 — Breaking-deltas declaration (FR-B8-3-030 → 040)

##### FR-B8-3-030 — declare the 1.0.0 → 2.0.0 breaking deltas
The schema MUST declare the breaking deltas so B.8.12/B.8.14 have a canonical
target-of-record. At minimum: Kong→Envoy (B.8.4), Temporal-intent→DBOS (B.8.5),
REST-bridge→Connect-RPC (B.8.6), implicit→Zitadel (B.8.7), Postgres-16→17+pgvector
(B.8.5/B.7). Each delta MUST cite the B.8 brick that delivers it.

##### FR-B8-3-031 — additive-first ordering recorded
The schema (or its header) MUST record that the migration is additive-first per
§4.1 (new components added in parallel before removal), and that the **actual
version bump + removal of Kong/Temporal/REST happens at B.8.14, not B.8.3**.

##### FR-B8-3-032 — Temporal delta reflects baseline truth
The Temporal→DBOS delta MUST be described as replacing a **documented intent,
not a running system** (B8-BASELINE §4 — no Temporal worker is deployed). The
schema MUST NOT imply a live Temporal workflow migration.

#### Cluster 5 — Coexistence & scaffoldability rules (FR-B8-3-040 → 050)

##### FR-B8-3-040 — coexistence with frozen 1.0.0
The 2.0.0 candidate MUST coexist with the frozen 1.0.0 `schema.yaml`; both files
remain present. The candidate MUST NOT supersede or deprecate the 1.0.0 schema
(that is B.8.14).

##### FR-B8-3-041 — not scaffoldable by default
The spec MUST define that a `candidate` 2.0.0 schema is **not scaffoldable by
default** (opt-in only) — `forge init --archetype full-stack-monorepo` MUST
continue to scaffold 1.0.0 until B.8.14 promotes 2.0.0 to `stable`. Whether
enforcing this requires a validator/scaffolder change is flagged in
ADR-B8-3-001/003 as a possible **separate brick** (NOT implemented in B.8.3).

##### FR-B8-3-042 — promotion trigger to stable
The spec MUST define the candidate→stable promotion trigger: promotion happens
at **B.8.14** after **B.8.12** proves zero regression on the 4 demos
(ADR-B8-3-003). Promotion is out of scope for B.8.3.

### Non-Functional Requirements

##### NFR-B8-3-001 — anti-hallucination grounding
Every pin/path/stage claim in the specs MUST be re-read from a live file
(validator scripts, `*.yaml` standards, `schema.yaml`, `B8-BASELINE.md`).
Contradictions (the `2.0.0.yaml`-vs-`schema.yaml` naming; the missing Envoy
standard pin) MUST be recorded, not normalized (Article III.4).

##### NFR-B8-3-002 — zero standard / template / schema-file mutation in B.8.3
This change MUST NOT edit any `.forge/standards/**`, `.forge/templates/**`, or
`.forge/schemas/**` file, and MUST NOT bump any Constitution version. It only
authors `b8-3-schema-candidate/{.forge.yaml, proposal.md, specs.md,
open-questions.md}`.

##### NFR-B8-3-003 — frozen 1.0.0 byte-identity preserved
`schema.yaml` and `full-stack-monorepo/1.0.0.tar.gz` MUST be byte-unchanged by
this change (respects B.8.2 freeze + its sha256 guard).

##### NFR-B8-3-004 — backward compatibility of existing gates
`validate-foundations.sh` (FR-GL-001), `verify.sh`, and `constitution-linter.sh`
MUST stay GREEN — they read `schema.yaml`, which is untouched. Adding a
sibling `2.0.0.yaml` later MUST NOT, by itself, break these gates (they read by
literal filename).

##### NFR-B8-3-005 — the candidate gates downstream bricks
The specs MUST establish that B.8.4–B.8.9 build templates **against** the
component SET + layer topology + breaking-deltas declared by the candidate
schema, and that B.8.12 asserts convergence to it. (Traceability requirement; no
runtime artifact.)

## BDD Acceptance Criteria

```gherkin
Scenario: The 2.0.0 target is declared without disturbing the frozen 1.0.0 flagship
  Given the frozen full-stack-monorepo/1.0.0 schema.yaml (stage stable, maintenance-freeze)
  And the ratified 2.0.0 component standards (dbos, postgres-17+pgvector, zitadel, connect-rpc)
  When the 2.0.0 candidate schema is authored from these specs
  Then it declares name=full-stack-monorepo, version=2.0.0, stage=candidate
  And it references each component's source standard instead of inlining version pins
  And it records the Envoy pin as deferred to B.8.4 (no standard source today)
  And it declares the Kong→Envoy / Temporal-intent→DBOS / REST→Connect / implicit→Zitadel / pg16→17+pgvector breaking deltas
  And schema.yaml (1.0.0) and 1.0.0.tar.gz remain byte-identical
  And full-stack-monorepo stays scaffoldable as 1.0.0 (the candidate is opt-in, promoted to stable at B.8.14)
```

## Anti-Hallucination Pass

- **`2.0.0.yaml` vs `schema.yaml`** — the validator reads `schema.yaml` by
  literal filename (`validate-foundations.sh:92`); a `2.0.0.yaml` sibling is
  invisible to all gates. Contradiction with plan §4.2 recorded → Q-001 /
  ADR-B8-3-001. **Resolved 2026-05-30 (maintainer)**: candidate at
  `2.0.0.yaml`, intentionally invisible to existing gates, validated by its own
  `b8-3.test.sh`; shared-validator rewiring is B.8.3.b.
- **Envoy pin** — no `*.yaml` standard pins a gateway (only `infra/kong.md`).
  The Envoy version is NOT invented here; deferred to B.8.4 (FR-B8-3-012).
- **Component pins** — sourced from the live `orchestration/persistence/identity/
  transport.yaml`, not from training data; referenced, not inlined (ADR-B8-3-002
  **decided reference-only 2026-05-30**).
- **Temporal** — described as doc-only intent (B8-BASELINE §4), not a running
  system; no MTBF/live-migration claim.
- **Independent review** — propose + specify artifacts passed independent
  code-reviewer APPROVE (no CRITICAL / HIGH / MEDIUM findings) 2026-05-30.

## Open Questions

Tracked in `open-questions.md`: Q-001 (`2.0.0.yaml` on-disk naming + validator
wiring → ADR-B8-3-001, **resolved 2026-05-30 option (a)**), Q-002 (inline pins
vs standard references → ADR-B8-3-002, **resolved 2026-05-30 reference-only**),
Q-003 (candidate semantics + promotion + scaffoldability → ADR-B8-3-003, open),
Q-004 (web-public / web-backoffice layer modeling → ADR-B8-3-004, open).
