# Proposal: b8-6-connect-rpc

<!-- Created: 2026-06-02 -->
<!-- Schema: default -->
<!-- Audit: B.8.6 (docs/new-archetypes-plan.md §4.2 — Connect-RPC templates brick; plan wording partially stale vs 1.0.0 reality, see Problem) -->

## Problem

The 2.0.0 candidate schema (`.forge/schemas/full-stack-monorepo/2.0.0.yaml`,
B.8.3) declares Connect-RPC as the target default transport:

```yaml
  - name: connect-rpc
    role: transport
    replaces: rest-bridge
    delivered_by: B.8.6
    standard: transport.yaml  # protocol: connect-rpc
```

with the breaking delta `rest-bridge → connect-rpc` (brick B.8.6, strategy
`additive-first`). The brick is **not delivered**: no transport subtree
exists under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/`
(only `infra/k8s/envoy-gateway/` from B.8.4 and `infra/postgres/` from
B.8.5 exist today).

### GROUND-TRUTH FINDING (Article III.4) — the plan row is partially stale

Plan §4.2 B.8.6 (lines 2308–2310) says: « `buf.gen.yaml` étendu avec
`protoc-gen-connect-go`, `protoc-gen-connect-es`,
`protoc-gen-connect-dart-community`. `tonic-build` continue côté serveur
Rust. » Re-read of the live tree (2026-06-02) shows **that extension already
shipped on the frozen 1.0.0 line** via `t5-connect-codegen` (archived
2026-05-06):

**Ground truth (re-read 2026-06-02, Article III.4):**

- `.forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl`
  already carries `buf.build/connectrpc/go:v1.19.2`,
  `buf.build/bufbuild/es:v2.2.0`, `buf.build/connectrpc/dart:v1.0.0`
  (FR-T5-CC-001..003). The plan's plugin name
  `protoc-gen-connect-dart-community` does not match the shipped plugin
  identity (`buf.build/connectrpc/dart`, published by `connectrpc.com` on
  pub.dev — official, not community) — naming drift to verify live (Q-004).
- `transport.yaml` is at **v1.2.0** with `protocol: connect-rpc` already the
  declared default and Rust pins `connectrpc = "=0.3.3"` (WAIVER),
  `buffa/buffa-types = "=0.3.0"` (CORRECTION, t5-cargo-pin-refresh),
  `connectrpc-build = "=0.3.3"`. Its top-of-file comment block still says
  "v1.1.0" — stale header.
- crates.io carries newer `connectrpc`/`buffa` lines (0.5.x / 0.6.0 observed
  2026-05-16); the **modernization `connectrpc 0.4.x/0.5.x/0.6.x` was
  explicitly deferred from T5.1.E to B.8 (T6)** — plan lines 734–735. That
  deferral lands in this brick.
- ADR-T5-003 deferred the **Rust S2S Connect client** to B.8 (T6) — this
  brick must land it or explicitly re-defer it (Q-003).
- Plan §13 caveat 2: **Connect-Dart is B.8 risk #1** — « si trop fragile au
  moment de T6, garder gRPC-Web standard via Envoy Gateway ». B.8.4 has
  delivered the Envoy templates that host that fallback.
- B.8.3 invariants bind this brick: 1.0.0 stays frozen (`schema.yaml` +
  templates + `1.0.0.tar.gz` byte-identical, B.8.2 sha256 guard), candidate
  stays `scaffoldable: false` until B.8.14, pins live in standards not in
  the schema (ADR-B8-3-002), removal of `rest-bridge` happens only at
  B.8.14 (FR-B8-3-031).

So the honest B.8.6 scope is **not** "extend buf.gen.yaml" (done) but:
**consecrate Connect-RPC as the 2.0.0 default transport via the versioned
template subtree, modernize the Rust Connect crate line, and flip the
2.0.0.yaml component to delivered — additive, 1.0.0 untouched.**

## Solution

When built, the B.8.6 brick MUST:

1. Create the versioned transport subtree
   `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/`
   (2.0.0 `buf.gen.yaml.tmpl` variant + `README.md.tmpl`) following the
   B.8.4/B.8.5 subtree convention — repo-wide scans skip `N.N.N/` subtrees
   (→ ADR-B86-002, Q-002).
2. Modernize the Rust Connect crate pins **for the 2.0.0 line only**:
   target line for `connectrpc` / `connectrpc-build` / `buffa` /
   `buffa-types` chosen **verify-then-pin LIVE at `/forge:implement`**
   (crates.io index check, b8-coroot lesson — never fabricate at
   propose/specify) (→ ADR-B86-001, Q-001). 1.0.0 pins UNTOUCHED.
3. Bump `transport.yaml` additively v1.2.0 → v1.3.0: per-schema-line pins
   block for 2.0.0, fix the stale "v1.1.0" header comment, append the
   `Updated` entry to `.forge/standards/REVIEW.md` (→ ADR-B86-005).
4. Flip `2.0.0.yaml` `connect-rpc` to delivered per the B.8.4 precedent
   (inline `# B.8.6 — delivered` annotation; keep `standard:
   transport.yaml` reference-only) **without breaking `b8-3.test.sh` 17/17
   nor `b8-3b.test.sh` 12/12**.
5. Document the **gRPC-Web-via-Envoy fallback posture** (risk #1) in the
   2.0.0 transport README, cross-referencing the B.8.4 Envoy templates
   (→ ADR-B86-003).
6. Retain `tonic-build` server-side Rust (plan B.8.6 wording + ADR-004
   KEEP; Article VII.2 preserved — gRPC stays native between services).
7. Land or explicitly re-defer the Rust S2S Connect client deferred by
   ADR-T5-003 (→ ADR-B86-004, Q-003).
8. Ship harness `.forge/scripts/tests/b8-6.test.sh` (~12 hermetic L1
   tests, mirror b8-4/b8-5), register it in `forge-ci.yml`, add the
   CHANGELOG `[Unreleased]` entry.
9. Run the full ~42-harness suite + gates before push (sibling-coupling
   lesson — `full_harness_suite_before_push`).

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B86-001 — connectrpc crate target line.** 0.6.x latest vs 0.5.x vs
  keep 0.3.3+WAIVER. **Lean:** newest line whose `buffa`/`buffa-types`
  compat matrix resolves live on crates.io; if the modern line breaks the
  `Router::into_axum_service()` integration shape, stay 0.3.3 with renewed
  WAIVER and a dated re-review trigger.
- **ADR-B86-002 — 2.0.0 subtree shape.** Full-copy `buf.gen.yaml.tmpl`
  vs delta-fragment. **Lean:** full copy (buf.gen.yaml is a standalone
  artifact; fragments suit compose files, not codegen manifests).
- **ADR-B86-003 — Connect-Dart posture.** Keep official
  `buf.build/connectrpc/dart` ≥ v1.0.0 as default with documented
  gRPC-Web-via-Envoy fallback. **Lean:** keep + fallback section in README
  (plan §13: do not block the migration on this single point).
- **ADR-B86-004 — Rust S2S Connect client.** Land now vs re-defer.
  **Lean:** re-defer to B.8.12 (E2E migration tests) unless the modern
  connectrpc line makes it a trivial template addition — decide at design
  with live crate docs.
- **ADR-B86-005 — transport.yaml versioning.** Additive 1.3.0 vs breaking
  2.0.0. **Lean:** additive 1.3.0 — `protocol: connect-rpc` has been the
  declared default since T5; this brick adds 2.0.0 pins and changes no
  semantic, so no `breaking_change: true` and no WAIVER needed.

Release vehicle: **v0.4.0-rc.9** (next rc after the B.8.5+B8O pair ships
in the current `[Unreleased]`; maintainer may batch).

## Scope In

- `.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/`
  (buf.gen.yaml.tmpl + README.md.tmpl).
- 2.0.0-line Rust Connect crate pin modernization (verify-then-pin live).
- `transport.yaml` v1.2.0 → v1.3.0 additive + stale-header fix +
  REVIEW.md ledger entry.
- `2.0.0.yaml` connect-rpc delivered-flip annotation.
- gRPC-Web fallback documentation (risk #1 mitigation).
- Harness `b8-6.test.sh` + forge-ci.yml registration + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **Any 1.0.0 touch** — templates, `schema.yaml`, snapshot tarball, Cargo
  pins (frozen per B.8.2; maintenance-freeze + sha256 guard).
- **REST-bridge removal** — happens only at B.8.14 (FR-B8-3-031,
  additive-first).
- **Envoy HTTPRoute rewiring for Connect paths** — B.8.4 territory if
  needed; this brick only documents the fallback posture.
- **Qwik web-public Connect-ES client** — B.8.9.
- **Zitadel / DBOS / migration script** — B.8.7 / cancelled-per-B8O /
  B.8.10.
- **Constitution amendment** — Articles VII.2/VIII.1 untouched; any
  amendment is B.8.14 (per B.8.4 precedent).
- **Schema promotion** — 2.0.0 stays `scaffoldable: false` until B.8.14.

## Impact

- **Users affected**: none until B.8.14 — 2.0.0 is not scaffoldable;
  1.0.0 adopters see zero change.
- **Technical impact**: new 2.0.0 subtree (2 templates), 1 standard bump
  (additive), 1 schema annotation flip, 1 new harness. No production code,
  no example-tree regeneration expected (decide at design).
- **Dependencies**: B.8.3 (candidate schema), B.8.4 (subtree convention +
  Envoy fallback host), T.5 (`t5-connect-codegen` +
  `t5-cargo-pin-refresh` upstream pins).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: this proposal precedes
  specs; no template will be written before `specs.md` + `design.md` +
  `tasks.md`.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the plan row's
  premise was re-read against the live tree before scoping (plugins
  already shipped on 1.0.0; plugin naming drift flagged Q-004); all new
  crate pins are verify-then-pin LIVE at `/forge:implement`, never
  fabricated here.
- **Article IV (Delta-based)**: specs will be ADDED FRs in a consolidated
  `.forge/specs/` file; `transport.yaml` bump is additive with REVIEW.md
  ledger entry.
- **Article V (Compliance gate)**: harness + gates (`verify.sh`,
  `constitution-linter.sh`, `validate-standards-yaml.sh`,
  `validate-change-yaml.sh`) must pass before status flips; full harness
  suite before push.
- **Article VII.2 (tonic gRPC SHALL — PRESERVED)**: tonic-build retained
  server-side; Connect remains the edge/client transport, gRPC stays
  native between services.
- **Article VIII.1 (Kong SHALL — IN FORCE, UNTOUCHED)**: additive brick;
  Kong removal and any VIII.1 amendment are B.8.14.
- **Article XII (Governance)**: no governance change; BDFL decision points
  recorded as ADRs at `/forge:design`.

## Open Questions (seed)

- **Q-001** — connectrpc modern line: 0.6.x vs 0.5.x vs keep 0.3.3+WAIVER;
  `buffa`/`buffa-types` compat matrix + axum integration shape on the
  modern line (→ ADR-B86-001; open, resolved at `/forge:design` with live
  crates.io + docs evidence).
- **Q-002** — 2.0.0 subtree scope: `buf.gen.yaml.tmpl` + README only, or
  also a 2.0.0 `transport_connect.rs.tmpl` variant if the modern crate
  line changes the adapter surface (→ ADR-B86-002; open).
- **Q-003** — Rust S2S Connect client (ADR-T5-003 deferral): land here or
  re-defer to B.8.12 (→ ADR-B86-004; open).
- **Q-004** — Connect-Dart plugin identity: plan says
  `protoc-gen-connect-dart-community`, 1.0.0 ships official
  `buf.build/connectrpc/dart:v1.0.0` — confirm current official plugin +
  version live; check whether the Dart generator line moved since
  2026-05-06 (→ ADR-B86-003; open).
