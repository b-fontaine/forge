# Spec: B.8.14 Promotion Flip (point-of-no-return, applied)

Canonical requirements for the B.8.14 flip — the ratify + enablement follow-up to
`b8-14-promotion-prep`. Source change: `b8-14-promotion-flip` (archived 2026-06-05,
audit B.8.14). Two ordered commits: C1 ratification (`818ba6b`), C2 enablement.
Independent review `wf_63f4ec3f-0ca` → APPROVE (lanes re-executed live).

## Requirements

### FR-FLIP-002: §VIII.1 amended → Envoy; Constitution v2.0.0
`.forge/constitution.md` §VIII.1 reads "Envoy Gateway SHALL be used as the API
gateway" (Kubernetes Gateway API; Connect-RPC replaces gateway REST↔gRPC
transcoding); `## Amendments` row #2 records the Kong→Envoy change + the BDFL
window-compression waiver; `**Version**: v2.0.0`. §VIII.2 (Temporal) UNCHANGED —
DBOS has no Rust SDK (B8O / ADR-B8O-001); `dbos-embedded` stays a future-option.

### FR-FLIP-001: BDFL waiver recorded honestly
`.forge/standards/REVIEW.md` carries a Correction Entry: the §VIII.1 ≥7-day window
opened 2026-06-04, compressed to ~1 day, ratified 2026-06-05 by BDFL authority —
NOT a fabricated "completed 7-day window".

### FR-FLIP-020: 2.0.0 schema promoted
`.forge/schemas/full-stack-monorepo/2.0.0.yaml`: `stage: candidate → stable`,
`scaffoldable: false → true`; the constitutional-prohibition block reworded to the
ratified state. `validate-foundations.sh` accepts the stable versioned sibling.

### FR-FLIP-021: Kong-less 2.0.0 scaffold composition (fresh-init ONLY)
A fresh `forge init --archetype full-stack-monorepo` produces a Kong-less /
Envoy-Gateway tree = the 1.0.0 template set MINUS the Kong copy-op, with
compose/.env/Taskfile re-pointed to Kong-less `2.0.0/` variants, PLUS the
`2.0.0/infra/k8s/envoy-gateway/` manifests. Mechanism: `overlay.sh` + `init.sh`
gain a backward-compatible `--plan <file>` flag (default `scaffold-plan.yaml`);
`scaffold-plan-2.0.0.yaml` drives the Kong-less render; `bin/forge-init-fsm-2.0.0.sh`
forwards `--plan scaffold-plan-2.0.0.yaml`. The byte-frozen 1.0.0 base + snapshot
are NEVER edited; the 1.0.0 root templates + `infra/` are untouched (b8-2/b8-12).

### FR-FLIP-022: scaffolder versioned-selection + scaffoldable:false guard (B.8.3.b)
`forge init` resolves the highest `stage: stable` + `scaffoldable: true` schema for
the archetype (`cli/src/domain/schema-version.ts`) and routes to its versioned
wrapper (`bin/forge-init-fsm-<version>.sh` when present; convention-based, no
dispatch-table parser change — annotated in `dispatch-table.yml`). When an
archetype's parsed schemas are ALL non-scaffoldable, init REFUSES (exit 3). An
archetype with no parseable versioned schema (e.g. mobile-only's differing field
shape) falls back to legacy name-only routing.

### FR-FLIP-023: New flip harness, RED-first, registered
`.forge/scripts/tests/b8-14-flip.test.sh` (9 L1 + 1 env-gated L2) asserts the
2.0.0 plan is Kong-less + Envoy/Connect-bearing, `overlay.sh --plan` renders a
Kong-less tree, the schema is promoted, the wrapper + CLI guard exist, the
constitution anchor holds, and — KEEP-green — the 1.0.0 plan still carries Kong
(migrate additive). L2 (`FORGE_B8_14_FLIP_LIVE`) runs a real `forge init` and
verifies the produced tree is Kong-less + Envoy. Registered in the forge-ci.yml
hardcoded array.

### FR-FLIP-024: b8-15 front-door activated; migrate stays additive
`b8-15.test.sh` _005 flipped from the skip-guard to real front-door assertions
(2.0.0 stable+scaffoldable + Kong-less plan). The migrate-flagship fsm-kong
additive assertion STAYS — 1.0.0 adopters keep Kong; b8-12 + b8-15 line ~225
remain green. Kong removal is fresh-scaffold composition ONLY (§VIII.1 is not
retroactive).

### FR-FLIP-030/031: Invariants + gates
`bin/forge-migrate-flagship.sh` removal behaviour, the frozen 1.0.0 base, and the
snapshot (b8-2 sha guard) are untouched. Full 54-harness suite + verify.sh
(414/0) + constitution-linter (61/0) OVERALL PASS; cli vitest 87/87.

### Scope boundary (B.8.14 = the Kong→Envoy flip)
Postgres-17/pgvector (B.8.5), Zitadel (B.8.7) and the Qwik web-public surface
(B.8.9) ship as additive overlays/fragments and via forge-migrate-flagship; wiring
them into fresh-init is OUT of this brick's scope (documented in
`scaffold-plan-2.0.0.yaml`).

<!-- Added in b8-14-promotion-flip change, 2026-06-05 -->
