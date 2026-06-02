# Specifications: b8-6-connect-rpc

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.6 (docs/new-archetypes-plan.md §4.2 — Connect-RPC templates brick;
     plan wording partially stale vs 1.0.0 reality — plugins already shipped on
     frozen 1.0.0 buf.gen.yaml.tmpl via t5-connect-codegen; real delta is the
     versioned 2.0.0 transport subtree + Rust crate modernization + standard bump) -->

**Namespace** : `FR-B86-*` / `NFR-B86-*` / `ADR-B86-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VII.2 (tonic gRPC
SHALL) is **PRESERVED** — tonic-build retained server-side; Connect remains the
edge/client transport. Article VIII.1 (Kong SHALL) is **PRESERVED** — additive
brick; Kong removal at B.8.14. This change ships **no production code** in the
running example tree: it authors template files + standard + schema annotation +
harness only.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-
Hallucination — external crate pins are verify-then-pin LIVE at `/forge:implement`;
see Ground-Truth section in proposal), IV (delta-based: all deliverables are
additive; 1.0.0 frozen assets untouched), V (harness + gates must pass before
status flips), VII.2 (tonic gRPC SHALL — in force, PRESERVED), VIII.1 (Kong
SHALL — in force, PRESERVED).

## GROUND-TRUTH FINDING (Article III.4) — plan row is partially stale

Re-read of the live tree (2026-06-02) reveals the three Connect plugins
(`buf.build/connectrpc/go:v1.19.2`, `buf.build/bufbuild/es:v2.2.0`,
`buf.build/connectrpc/dart:v1.0.0`) **already shipped on the frozen 1.0.0 line**
via `t5-connect-codegen` (archived 2026-05-06), satisfying FR-T5-CC-001..003.
The plan §4.2 plugin name `protoc-gen-connect-dart-community` does not match the
shipped official identity `buf.build/connectrpc/dart` (Q-004 — verify live).
The real B.8.6 delta is:

1. **Versioned 2.0.0 transport subtree**: `2.0.0/shared/protos/buf.gen.yaml.tmpl`
   + `README.md.tmpl` consecrating Connect-RPC as the 2.0.0 default transport.
2. **Rust Connect crate-pin modernization** for the 2.0.0 line only (verify-then-pin
   LIVE at `/forge:implement` — never fabricated at propose/specify/design).
3. **`transport.yaml` additive bump v1.2.0 → v1.3.0**: per-schema-line pins block
   for 2.0.0 + fix stale "v1.1.0" header comment + REVIEW.md ledger entry.
4. **`2.0.0.yaml` `connect-rpc` delivered-flip annotation** (B.8.4 precedent).
5. **gRPC-Web-via-Envoy fallback documentation** (plan §13 risk #1).
6. **Harness `b8-6.test.sh`** + `forge-ci.yml` registration + CHANGELOG entry.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.2 B.8.6 (GROUND-TRUTH NOTE: plugin extension partially stale; see proposal) |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (B.8.3, candidate, `scaffoldable: false`) — component `connect-rpc` { role: transport, replaces: rest-bridge, delivered_by: B.8.6, standard: transport.yaml }; migration_delta { from: rest-bridge, to: connect-rpc, brick: B.8.6, strategy: additive-first } |
| **transport.yaml (observed)** | v1.2.0 (stale header comment says "v1.1.0") — `protocol: connect-rpc`, `fallback: grpc-web`, Rust pins `connectrpc = "=0.3.3"` (WAIVER), `buffa = "=0.3.0"` (CORRECTION), `buffa-types = "=0.3.0"` (CORRECTION), `connectrpc-build = "=0.3.3"` (WAIVER). Modernization 0.3.x → current was explicitly deferred from T5.1.E to B.8 (plan lines 734-735). |
| **1.0.0 buf.gen.yaml.tmpl (observed)** | `.forge/templates/archetypes/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` — already carries the 3 Connect plugins (FR-T5-CC-001..003). Frozen (B.8.2). |
| **2.0.0 template tree (observed)** | `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` contains `infra/k8s/envoy-gateway/` (B.8.4) and `infra/postgres/` (B.8.5). No `shared/protos/` subtree exists yet — this brick delivers it. |
| **ADR-T5-003 (observed)** | Demo-005 ships TS-only; Rust S2S Connect client deferred to B.8 (T6). This brick must land it or explicitly re-defer it (Q-003). |
| **Standard bump precedent (observed)** | `transport.yaml` 1.0.0 → 1.1.0 → 1.2.0 additive; `gateway.yaml` created by B.8.4 (REVIEW.md precedent). REVIEW.md is append-only (Article XII). J.7 = `bin/validate-standards-yaml.sh`. |
| **B.8.3 invariants (binding)** | 1.0.0 stays frozen; candidate stays `scaffoldable: false` until B.8.14; pins live in standards not in schema (ADR-B8-3-002); REST-bridge removed only at B.8.14 (FR-B8-3-031). |
| **Test harness coupling** | `b8-3.test.sh` (17 L1): forbidden inline-pin keys `{version,pin,image}` (T-012), forbidden scalar `^\d+\.\d+` (T-015), every `standard:` ref must resolve (T-011), component must have `name` (T-010). `b8-3b.test.sh` (12 L1). Editing 2.0.0.yaml MUST keep both GREEN. |
| **Subtree scan convention** | Repo-wide scans skip `N.N.N/` subtrees (established by B.8.4/B.8.5); b8-6 inherits this. |
| **Dependencies** | B.8.3 (candidate schema), B.8.4 (subtree convention + delivered-flip precedent + Envoy fallback host), B.8.5 (postgres precedent), T.5 (`t5-connect-codegen` frozen 1.0.0 plugins + `t5-cargo-pin-refresh` 0.3.x pin baseline). |
| **Release target** | v0.4.0-rc.9 (next rc after B.8.5 + B8O pair; maintainer may batch) |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — Versioned 2.0.0 transport subtree (FR-B86-001 → 009)

##### FR-B86-001 — 2.0.0 shared/protos/ subtree created
The brick MUST create the versioned transport subtree at
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/shared/protos/`
containing at minimum: `buf.gen.yaml.tmpl` and `README.md.tmpl`. The subtree
MUST follow the `N.N.N/` versioned-subtree convention established by B.8.4
(envoy-gateway) and B.8.5 (postgres) — repo-wide scans skip it (ADR-B86-002).

##### FR-B86-002 — 2.0.0 buf.gen.yaml.tmpl is a full copy, not a fragment
The `2.0.0/shared/protos/buf.gen.yaml.tmpl` MUST be a **full standalone copy**
of the codegen manifest (ADR-B86-002 lean: full copy — buf.gen.yaml is a
self-contained artifact; delta fragments suit compose files, not codegen
manifests). It MUST NOT import or reference the 1.0.0 `shared/protos/
buf.gen.yaml.tmpl` — each schema-version's codegen manifest is independently
owned by its subtree.

##### FR-B86-003 — 2.0.0 buf.gen.yaml.tmpl preserves all 1.0.0 plugin entries
The 2.0.0 `buf.gen.yaml.tmpl` MUST carry all six plugin entries from the
frozen 1.0.0 manifest: `neoeinstein-tonic`, `neoeinstein-prost`,
`protocolbuffers/dart` (gRPC Rust + Dart stubs), plus the three Connect plugins
`buf.build/connectrpc/go`, `buf.build/bufbuild/es`, `buf.build/connectrpc/dart`
(FR-T5-CC-001..003), preserving FR-T5-CC-004 (tonic gRPC codegen untouched) and
Article VII.2 (tonic gRPC SHALL server-side).

##### FR-B86-004 — 2.0.0 buf.gen.yaml.tmpl carries modernized Connect-Dart version reference
The 2.0.0 manifest MUST carry the Connect-Dart plugin entry
(`buf.build/connectrpc/dart`) at a version **verified live at `/forge:design`**
against the Buf Schema Registry (BSR). If the official plugin has advanced beyond
`v1.0.0` (the 1.0.0 frozen baseline), the 2.0.0 line picks up the live version;
if `v1.0.0` is still current, it is retained. The concrete version string is
**never fabricated here** (Article III.4 / Q-004 / ADR-B86-003). The 1.0.0
frozen manifest stays `buf.build/connectrpc/dart:v1.0.0` byte-for-byte.

##### FR-B86-005 — README.md.tmpl documents the 2.0.0 transport subtree
The brick MUST ship `2.0.0/shared/protos/README.md.tmpl` documenting: (a)
Connect-RPC as the 2.0.0 default transport, (b) the additive posture vs the
frozen 1.0.0 codegen manifest, (c) the gRPC-Web-via-Envoy fallback for Connect-
Dart (plan §13 risk #1 mitigation — cross-reference the B.8.4 Envoy templates),
(d) the verify-then-pin note for the modern Rust crate line, and (e) the
policy-source reference to `transport.yaml`. Mirrors the postgres README exemplar
format (B.8.5 ADR-B85-002 / `infra/postgres/README.md.tmpl`).

##### FR-B86-006 — tonic-build retained server-side in the 2.0.0 codegen manifest
The 2.0.0 `buf.gen.yaml.tmpl` MUST retain the `neoeinstein-tonic` remote plugin
entry for Rust gRPC server-side codegen (ADR-B86-004 KEEP — Article VII.2
preserved: gRPC stays native between services). The Connect adapter mounts on a
separate axum router under `/connect`, as established by FR-T5-CC-011.

##### FR-B86-007 — 1.0.0 shared/protos/buf.gen.yaml.tmpl byte-unchanged
The frozen 1.0.0 `shared/protos/buf.gen.yaml.tmpl` (six plugin entries,
FR-T5-CC-001..004) MUST be byte-unchanged by this brick. Only the NEW
`2.0.0/shared/protos/` path is added (B.8.2 maintenance freeze). Any diff
touching the 1.0.0 manifest is a constitutional violation.

##### FR-B86-008 — transport subtree visible but scaffoldable: false
The new `2.0.0/shared/protos/` subtree is an on-disk asset for the 2.0.0
candidate. The candidate remains `scaffoldable: false` until B.8.14 (ADR-B8-3-003/
005). `forge init` still emits the flat 1.0.0 manifest; this subtree is spliced
in at B.8.14 when the candidate is promoted. No scaffolder change ships in this
brick.

##### FR-B86-009 — gRPC-Web-via-Envoy fallback documented in the 2.0.0 README
The `README.md.tmpl` MUST include a dedicated section documenting the **gRPC-Web-
via-Envoy fallback posture** (plan §13 caveat 2 — Connect-Dart risk #1): if
Connect-Dart proves too fragile at B.8.14 deployment, Envoy Gateway (B.8.4
templates) exposes a gRPC-Web endpoint without changing the Rust server. The
section MUST reference the path `2.0.0/infra/k8s/envoy-gateway/` and state the
fallback is available without waiting for Connect-Dart maturation (ADR-B86-003).

---

#### Group 2 — Rust crate-pin modernization (2.0.0 line only) (FR-B86-010 → 015)

##### FR-B86-010 — modern Rust Connect crate line is verify-then-pin at /forge:implement
The brick MUST modernize the Rust Connect crate pins (`connectrpc`,
`connectrpc-build`, `buffa`, `buffa-types`) for the **2.0.0 line only**. The
target crate versions MUST be **resolved live from crates.io** at
`/forge:implement` (the b8-coroot lesson — never fabricate version strings at
propose/specify). This spec treated the target line as a design-time
decision — **RESOLVED at /forge:design via live crates.io evidence
(ADR-B86-001, Q-001): `connectrpc`/`connectrpc-build` `=0.6.1` +
`buffa`/`buffa-types` `=0.6.0`** — re-verified live at /forge:implement
2026-06-02T13:35Z (evidence.md P-12).

##### FR-B86-011 — 1.0.0 Rust pins byte-unchanged
The 1.0.0 Rust crate pins (`connectrpc = "=0.3.3"` WAIVER, `buffa = "=0.3.0"`
CORRECTION, `buffa-types = "=0.3.0"` CORRECTION, `connectrpc-build = "=0.3.3"`
WAIVER) in `transport.yaml` MUST be byte-unchanged. Only the **2.0.0-specific
pins block** added by FR-B86-021 carries the modernized versions.

##### FR-B86-012 — modern line must resolve the buffa compat matrix live
The chosen modern `connectrpc` / `connectrpc-build` version MUST have a `buffa` /
`buffa-types` compat matrix that resolves without conflict on crates.io at
`/forge:design` (the T5.1.E lesson: `buffa = "=0.3.3"` was an error-of-fact
because 0.3.x stopped at 0.3.0). If the modern line's `buffa` compat cannot be
resolved, the fallback is 0.3.3 + renewed WAIVER + a dated re-review trigger
(ADR-B86-001 lean). Resolution is a `/forge:design` gate, not a `/forge:specify`
gate.

##### FR-B86-013 — axum integration shape verified on the modern line
The `Router::into_axum_service()` integration shape (FR-T5-CC-010 — established
by the T.5 spike) MUST be verified against the chosen modern `connectrpc` crate
at `/forge:design` before the line is selected. If the API surface changed
incompatibly, the design MUST surface this as a constraint on ADR-B86-001 (lean:
stay 0.3.3 with renewed WAIVER if the modern line breaks the integration shape).

##### FR-B86-014 — Rust S2S Connect client: land or explicitly re-defer
ADR-T5-003 deferred the Rust S2S Connect client to B.8 (T6). This brick MUST
either (a) land a minimal `transport_connect_client.rs.tmpl` in the 2.0.0 subtree
if the modern crate line makes it a trivial template addition, or (b) explicitly
re-defer it to B.8.12 with a dated note in `design.md` and an updated reference
in `.forge/specs/connect-codegen.md` ADR-T5-003 (→ ADR-B86-004, Q-003). A
silent omission (neither landed nor re-deferred) is a constitutional violation.

##### FR-B86-015 — 2.0.0-line pins isolated, never inline in 2.0.0.yaml
The modern Rust crate pin versions MUST NOT appear as inline scalar values in
`2.0.0.yaml` (ADR-B8-3-002 — b8-3 T-012 / T-015). They live exclusively in
`transport.yaml` under the per-schema-line block added by FR-B86-021.

---

#### Group 3 — transport.yaml v1.2.0 → v1.3.0 additive bump (FR-B86-020 → 026)

##### FR-B86-020 — transport.yaml bumped additively v1.2.0 → v1.3.0
The brick MUST bump `.forge/standards/transport.yaml` from `version: "1.2.0"` to
`version: "1.3.0"` (additive — no breaking change; `protocol: connect-rpc` has
been the declared default since T.5; this bump adds 2.0.0 pins and changes no
semantic). `breaking_change: true` is NOT set (ADR-B86-005 lean). The existing
v1.0.0 → v1.1.0 → v1.2.0 body fields and WAIVER / CORRECTION comments MUST be
preserved verbatim.

##### FR-B86-021 — per-schema-line pins block for 2.0.0 added to transport.yaml
The v1.3.0 transport.yaml MUST add a `schema_versions:` (or equivalent additive
field — shape is ADR-B86-005) block containing the modernized 2.0.0-line Rust
crate pins (`connectrpc`, `connectrpc-build`, `buffa`, `buffa-types`) for
`schema: "2.0.0"` only. The exact field name and nesting are resolved at
`/forge:design`; this spec requires **the 1.0.0 and 2.0.0 pin sets to be
separately addressable by schema version** so tooling and harnesses can
distinguish them. **RESOLVED at /forge:design (ADR-B86-005): sibling block
`codegen.versions_2_0_0:`** — shipped in transport.yaml v1.3.0.

##### FR-B86-022 — stale "v1.1.0" header comment fixed
The `transport.yaml` top-of-file audit-comment block still says "v1.1.0" (drift
from the live `version: "1.2.0"` field). The v1.3.0 edit MUST fix this: the
header comment MUST reflect `v1.3.0` and record the B.8.6 change (additive:
2.0.0-line Rust pins block + stale-header fix). No other header comment is
changed.

##### FR-B86-023 — REVIEW.md ledger receives a B.8.6 entry
`.forge/standards/REVIEW.md` MUST receive an append-only `Updated` entry for
`transport.yaml v1.3.0`, dated 2026-06-02 (the B.8.6 specify date), with a one-
line description of the change (additive: 2.0.0-line crate pins + header fix).
Mirrors the B.8.4 `gateway.yaml` and B.8.5 `orchestration.yaml` REVIEW.md
precedents (Article XII append-only ledger).

##### FR-B86-024 — transport.yaml v1.3.0 passes J.7 validate-standards-yaml.sh
After the v1.3.0 edit, `bin/validate-standards-yaml.sh` (J.7) MUST pass in both
single-file mode and directory mode. The MANDATORY `REVIEW.md` row for
`transport.yaml | 1.3.0` (FR-J7-023) is satisfied by FR-B86-023. The `expires_at:
never` / `exception_constitutional: true` frontmatter from the structural exception
declaration MUST be preserved (these values already keep j7 green for the existing
transport.yaml versions).

##### FR-B86-025 — 1.0.0 transport.yaml pins untouched
The existing v1.2.0 Rust pin fields (`connectrpc = "=0.3.3"` WAIVER,
`buffa = "=0.3.0"` CORRECTION, `buffa-types = "=0.3.0"` CORRECTION,
`connectrpc-build = "=0.3.3"` WAIVER) and all codegen version fields (buf,
protoc-gen-connect-go, protoc-gen-es, etc.) MUST be preserved byte-identical
through the v1.3.0 bump (FR-B86-011). Only the 2.0.0 pins block and the header
comment are new or changed.

##### FR-B86-026 — No WAIVER required for the transport.yaml bump
The v1.2.0 → v1.3.0 bump is purely additive (new schema_versions block +
comment fix; no semantic field changed). `breaking_change: false` (ADR-B86-005
lean: 1.3.0 not 2.0.0). No WAIVER commentary is needed for the bump itself
(WAIVERs may be needed for the new Rust crate pins inside the block — those are
ADR-B86-001 territory, resolved at `/forge:design`).

---

#### Group 4 — 2.0.0.yaml delivered-flip annotation (FR-B86-030 → 034)

##### FR-B86-030 — connect-rpc component annotated # B.8.6 — delivered
The `2.0.0.yaml` `connect-rpc` component MUST receive an inline comment
`# B.8.6 — delivered` on or adjacent to the `delivered_by: B.8.6` line,
following the B.8.4 precedent (envoy-gateway annotation). The `standard:
transport.yaml` reference-only annotation MUST be preserved (not replaced by an
inline pin — ADR-B8-3-002).

##### FR-B86-031 — delivered annotation MUST NOT break b8-3 / b8-3b
The annotation MUST NOT introduce a forbidden inline-pin key (`version`/`pin`/
`image` — b8-3 T-012) and MUST NOT add a component scalar value matching
`^\d+\.\d+` (b8-3 T-015). The `connect-rpc` `name`, `standard: transport.yaml`
ref (T-010/T-011), and the `rest-bridge → connect-rpc` migration_delta
(strategy: additive-first) MUST remain intact. After the annotation, `b8-3.test.sh`
(17 L1) and `b8-3b.test.sh` (12 L1) MUST stay GREEN.

##### FR-B86-032 — rest-bridge NOT removed from 2.0.0.yaml
The `rest-bridge → connect-rpc` migration delta MUST remain intact with
`strategy: additive-first`. REST-bridge removal from the candidate schema happens
only at B.8.14 (FR-B8-3-031, additive-first). No `from: rest-bridge` row is
deleted by this brick.

##### FR-B86-033 — annotation shape mirrors B.8.4 envoy-gateway delivered-flip
The inline comment style (`# B.8.6 — delivered`) MUST mirror the envoy-gateway
delivered-flip annotation in `2.0.0.yaml` so that the candidate schema is
consistently annotated across delivered bricks. The exact formatting (spacing,
dash vs em-dash) is resolved at `/forge:design` by inspecting the live B.8.4
annotation.

##### FR-B86-034 — 2.0.0.yaml edit satisfies all existing b8-3 / b8-3b test assertions
The edit MUST be regression-tested by running `b8-3.test.sh` (17/17) and
`b8-3b.test.sh` (12/12) after the annotation. Both MUST exit 0. The b8-6 harness
MUST include an exit-code coupling guard (mirroring b8-5 T-009).

---

#### Group 5 — gRPC-Web-via-Envoy fallback documentation (FR-B86-040 → 043)

##### FR-B86-040 — fallback posture documented in the 2.0.0 README
The `2.0.0/shared/protos/README.md.tmpl` MUST include a section titled
"gRPC-Web-via-Envoy Fallback (Connect-Dart Risk #1)" (or equivalent) documenting
the plan §13 caveat 2: if Connect-Dart proves too fragile at B.8.14 deployment,
Flutter can fall back to gRPC-Web via the Envoy Gateway (B.8.4) without changing
the Rust server (FR-B86-009). The section MUST cross-reference the Envoy template
path `2.0.0/infra/k8s/envoy-gateway/`.

##### FR-B86-041 — fallback is documentation only — no Envoy HTTPRoute change
This brick MUST NOT modify any file under `2.0.0/infra/k8s/envoy-gateway/` (B.8.4
territory). The fallback is documented as an option, not deployed. Any Envoy
HTTPRoute rewiring for Connect paths remains B.8.4 territory (Scope Out,
proposal).

##### FR-B86-042 — Connect-Dart stays the default; fallback is conditional
The README documentation MUST establish Connect-Dart (`buf.build/connectrpc/dart`)
as the **default** Dart transport for 2.0.0 (ADR-B86-003 lean: keep + fallback
section). The gRPC-Web fallback is presented as a conditional option (if
Connect-Dart is too fragile), not as the primary path. The tonic gRPC server-side
endpoint is preserved (Article VII.2 / FR-B86-006), enabling both transports
simultaneously without a server change.

##### FR-B86-043 — fallback section references ADR-B86-003 and Q-004
The README fallback section MUST note that the Connect-Dart plugin identity and
version are subject to live verification at `/forge:design` / `/forge:implement`
(Q-004 — plan naming drift `protoc-gen-connect-dart-community` vs official
`buf.build/connectrpc/dart` — article III.4). If the official plugin has changed
since v1.0.0, the README reflects the verified identity.

---

#### Group 6 — Harness b8-6.test.sh + forge-ci.yml + CHANGELOG (FR-B86-050 → 059)

##### FR-B86-050 — harness file created, hermetic, ≤ 2 s L1, registered
The brick MUST ship `.forge/scripts/tests/b8-6.test.sh` with: `--level` flag,
`source _helpers.sh`, `run_test`, `print_summary` (mirroring b8-4 / b8-5 harness
structure). L1 wall-clock budget **≤ 2 s** (NFR-B86-001 — tighter than b8-5's
5 s; transport subtree tests are grep/stat only, no docker/network). Zero
network or Docker calls at L1. MUST be registered as a one-line entry
`"b8-6.test.sh --level 1"` in `.github/workflows/forge-ci.yml` after the
`b8-5.test.sh` line.

##### FR-B86-051 — harness asserts 2.0.0/shared/protos/ subtree exists
The harness MUST assert that both `2.0.0/shared/protos/buf.gen.yaml.tmpl` and
`2.0.0/shared/protos/README.md.tmpl` exist (FR-B86-001). A missing file is a
FAIL.

##### FR-B86-052 — harness asserts 2.0.0 buf.gen.yaml.tmpl carries all 7 plugins
The harness MUST assert the 2.0.0 `buf.gen.yaml.tmpl` contains all six plugin
remote references: `neoeinstein-tonic`, `neoeinstein-prost`, `protocolbuffers/dart`,
`connectrpc/go`, `bufbuild/es`, `connectrpc/dart` (FR-B86-003 / FR-B86-006).

##### FR-B86-053 — harness asserts 1.0.0 buf.gen.yaml.tmpl byte-unchanged
The harness MUST assert the frozen 1.0.0 `shared/protos/buf.gen.yaml.tmpl` still
carries `buf.build/connectrpc/dart:v1.0.0` (its shipped version sentinel) and
that the file is NOT modified by this brick (FR-B86-007 / NFR-B86-003).

##### FR-B86-054 — harness asserts transport.yaml at v1.3.0 + header fixed
The harness MUST assert `transport.yaml` `version:` field is `"1.3.0"` and that
the header comment no longer says `"v1.1.0"` (FR-B86-020 / FR-B86-022).

##### FR-B86-055 — harness asserts transport.yaml 2.0.0 pins block present
The harness MUST assert the v1.3.0 transport.yaml contains a 2.0.0-schema pins
block (whatever the ADR-B86-005-chosen key name) with at least the four Rust
crate keys (`connectrpc`, `connectrpc-build`, `buffa`, `buffa-types`) referencing
non-WAIVER / non-CORRECTION content for the 2.0.0 line (FR-B86-021). The exact
grep pattern is determined at `/forge:design` after ADR-B86-005 resolves the
block shape.

##### FR-B86-056 — harness asserts REVIEW.md B.8.6 entry present
The harness MUST assert `.forge/standards/REVIEW.md` contains a row referencing
`transport.yaml` and `1.3.0` (FR-B86-023). Mirrors b8-5 T-007 REVIEW.md assertion.

##### FR-B86-057 — harness asserts 2.0.0.yaml connect-rpc delivered annotation
The harness MUST assert the 2.0.0.yaml `connect-rpc` component carries the
delivered annotation comment and that `standard: transport.yaml` still resolves
(FR-B86-030 / FR-B86-031). The `rest-bridge → connect-rpc` migration_delta MUST
still be present with `strategy: additive-first` (FR-B86-032).

##### FR-B86-058 — harness coupling guard: b8-3 (17/17) + b8-3b (12/12) GREEN
The harness MUST run `b8-3.test.sh --level 1` and `b8-3b.test.sh --level 1` as
exit-code-only coupling guards (the b8-4 T-012 / b8-5 T-009 strategy). Both MUST
exit 0 for the b8-6 harness to PASS. Any breakage of the existing b8-3 or b8-3b
gate is a b8-6 FAIL.

##### FR-B86-059 — CHANGELOG [Unreleased] entry added
The brick MUST add a `## [Unreleased]` section entry in `CHANGELOG.md`
summarising the B.8.6 deliverables (2.0.0 transport subtree, Rust pin
modernization, transport.yaml v1.3.0, 2.0.0.yaml annotation, harness). Mirrors
the B.8.4 / B.8.5 CHANGELOG precedent.

---

### Non-Functional Requirements

##### NFR-B86-001 — harness L1 ≤ 2 s wall-clock (hermetic)
The `b8-6.test.sh` L1 harness wall-clock MUST be ≤ **2 s** on the CI runner (no
network, no Docker, no cargo build). All assertions are grep / stat / file-exists
operations. This mirrors the NFR-J7-001 style budget and is tighter than b8-5's
5 s (transport subtree tests are simpler than postgres + orchestration.yaml
assertions).

##### NFR-B86-002 — frozen 1.0.0 byte-identity preserved
The frozen `schema.yaml` (1.0.0), the flat 1.0.0 template tree (including
`shared/protos/buf.gen.yaml.tmpl` with its six plugin entries), and
`full-stack-monorepo/1.0.0.tar.gz` MUST be byte-unchanged by this brick AND by the
downstream implementation. Respects B.8.2 maintenance freeze + sha256 guard
(B.8.3 invariant).

##### NFR-B86-003 — b8-3.test.sh (17/17) + b8-3b.test.sh (12/12) stay GREEN
All existing B.8.3 schema gates MUST stay GREEN after every file touched by this
brick. This is a hard gate: a FAIL in either harness constitutes a B.8.6
constitutional violation (Article V.2). The b8-6 harness enforces this as a
coupling guard (FR-B86-058).

##### NFR-B86-004 — full ~42-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~42 harnesses in
`.forge/scripts/tests/`) MUST pass (the `full_harness_suite_before_push` lesson —
sibling scans can break silently). This includes `b8-3`, `b8-3b`, `b8-4`, `b8-5`,
`b8-6`, and any other harness whose repo-wide scan could be affected by the new
`2.0.0/shared/protos/` subtree.

##### NFR-B86-005 — zero new external dependencies
This brick MUST NOT introduce any new external dependency (no new npm package, no
new crate beyond the verify-then-pin modernized versions already tracked in
transport.yaml, no new binary). The 2.0.0 template subtree and the standard bump
are file-only changes.

##### NFR-B86-006 — verify-then-pin at implement (no premature crate pins)
The specs and design MUST treat the concrete modern Rust crate versions
(`connectrpc`, `connectrpc-build`, `buffa`, `buffa-types` for 2.0.0) as
**deferred** to a live verification step at `/forge:implement` (crates.io index
check). A concrete version written before live verification is a constitutional
anti-hallucination failure (Article III.4; b8-coroot lesson). Until implemented,
the versions are identified by their policy intent only ("the newest line whose
buffa compat matrix resolves live" — ADR-B86-001 lean).

##### NFR-B86-007 — Article VII.2 preserved (tonic gRPC SHALL — KEPT)
The specs MUST establish that `tonic-build` is **retained** server-side in the
2.0.0 codegen manifest (FR-B86-006). Connect is the edge/client transport; gRPC
stays native between services. No spec in this brick alters Article VII.2 or
proposes its amendment. Article VII.2 amendment is B.8.14 territory.

##### NFR-B86-008 — Article VIII.1 preserved (Kong SHALL — UNTOUCHED)
This brick is additive. Kong removal and any VIII.1 amendment are B.8.14. The
2.0.0.yaml `connect-rpc` delivered-flip does NOT authorize removing Kong from any
live stack. The candidate remains `scaffoldable: false`.

##### NFR-B86-009 — independent review required before /forge:design
These specs MUST pass an **independent reviewer** (not the author) before
`/forge:design` proceeds. Self-approval of the anti-hallucination pass (Article
III.4) and of the open-questions leanings is prohibited. The verify-then-pin items
(Rust crate versions, Connect-Dart BSR version) are NOT resolved here.

---

## Architecture Decision Records (seeds — finalized at /forge:design)

- **ADR-B86-001 — connectrpc crate target line for 2.0.0.** Lean: the newest
  published line whose `buffa`/`buffa-types` compat matrix resolves live on
  crates.io AND whose `Router::into_axum_service()` shape is unchanged; if the
  modern line breaks the integration shape or the buffa matrix is unresolvable,
  stay 0.3.3 + renewed WAIVER + dated re-review trigger. Resolved at
  `/forge:design` via live crates.io + Context7 crate docs.
- **ADR-B86-002 — 2.0.0 subtree shape.** Full-copy `buf.gen.yaml.tmpl` vs delta-
  fragment. Lean: full copy. Whether to also ship a 2.0.0 `transport_connect.rs.tmpl`
  Rust adapter variant (if the modern crate line changes the adapter surface) is
  open (Q-002); scope is `buf.gen.yaml.tmpl` + `README.md.tmpl` unless the adapter
  surface forces an additional file (decided at design with live crate docs).
- **ADR-B86-003 — Connect-Dart posture.** Keep official `buf.build/connectrpc/dart`
  ≥ v1.0.0 as 2.0.0 default with documented gRPC-Web-via-Envoy fallback. Lean:
  keep + fallback section. Q-004 (live plugin identity + version) resolved at
  `/forge:design`.
- **ADR-B86-004 — Rust S2S Connect client (ADR-T5-003 deferral).** Lean:
  re-defer to B.8.12 unless the modern crate line makes it a trivial template
  addition. Decided at `/forge:design` with live crate docs (Q-003).
- **ADR-B86-005 — transport.yaml schema_versions block shape.** Lean: additive
  1.3.0 — no breaking_change; new `schema_versions:` block (or equivalent)
  distinguishing 1.0.0 vs 2.0.0 pin sets. Exact key name resolved at
  `/forge:design` by inspecting transport.yaml + validate-standards-yaml.sh
  schema.

---

## BDD Acceptance Criteria

```gherkin
Feature: Connect-RPC consecrated as the 2.0.0 default transport via versioned subtree, standard bump, and schema annotation
  As a Forge B.8 migration architect
  I want the Connect-RPC transport subtree, Rust crate modernization, and standard bump
  delivered additively for the 2.0.0 candidate
  So that the flagship gains a versioned codegen manifest with modernized pins,
  the transport standard is properly versioned, and the 1.0.0 frozen stack is untouched

  Scenario: The 2.0.0 transport subtree is created additively without disturbing the frozen 1.0.0 manifest
    Given the frozen 1.0.0 buf.gen.yaml.tmpl at shared/protos/ carrying all 7 plugin entries (FR-T5-CC-001..004)
    And no 2.0.0/shared/protos/ subtree existing yet
    And the 2.0.0 candidate schema declaring connect-rpc (delivered_by: B.8.6, standard: transport.yaml)
    And transport.yaml at v1.2.0 with stale v1.1.0 header comment
    And b8-3.test.sh (17 L1) and b8-3b.test.sh (12 L1) GREEN
    When the B.8.6 brick is implemented from these specs
    Then the 2.0.0/shared/protos/buf.gen.yaml.tmpl and README.md.tmpl exist as new additive files
    And the 2.0.0 buf.gen.yaml.tmpl carries all 7 plugin entries including tonic-build (Article VII.2 preserved)
    And the frozen 1.0.0 buf.gen.yaml.tmpl is byte-unchanged (sha256 guard, B.8.2)
    And transport.yaml is version "1.3.0" with the stale header comment fixed
    And transport.yaml carries a 2.0.0 per-schema pins block with modernized Rust crate versions (verify-then-pin at /forge:implement)
    And the 1.0.0 Rust pin lines (=0.3.3 WAIVER / =0.3.0 CORRECTION) are byte-unchanged
    And REVIEW.md has a new transport.yaml 1.3.0 ledger entry
    And 2.0.0.yaml connect-rpc component carries a # B.8.6 — delivered annotation
    And the rest-bridge → connect-rpc migration_delta strategy: additive-first is intact
    And b8-3.test.sh (17/17) and b8-3b.test.sh (12/12) stay GREEN
    And b8-6.test.sh passes all L1 checks within 2 s

  Scenario: The gRPC-Web-via-Envoy fallback is documented but not deployed, preserving Connect-Dart as the default
    Given the 2.0.0 buf.gen.yaml.tmpl carrying buf.build/connectrpc/dart as the Dart transport plugin
    And the Envoy Gateway templates at 2.0.0/infra/k8s/envoy-gateway/ (B.8.4)
    And no modification to any B.8.4 Envoy template file
    When a maintainer reads the 2.0.0/shared/protos/README.md.tmpl
    Then the README documents gRPC-Web-via-Envoy as a conditional fallback for Connect-Dart risk #1
    And the README establishes Connect-Dart as the default Dart transport for 2.0.0
    And the README cross-references the Envoy Gateway path 2.0.0/infra/k8s/envoy-gateway/
    And no Envoy HTTPRoute or gateway manifest is modified by this brick
    And the Rust server-side tonic endpoint remains unchanged (Article VII.2)

  Scenario: Scaffolding a 2.0.0 candidate remains refused until B.8.14
    Given the 2.0.0.yaml candidate with scaffoldable: false (ADR-B8-3-003/005)
    And the new 2.0.0/shared/protos/ subtree present on disk
    When forge init is invoked
    Then the scaffolder still emits the flat 1.0.0 buf.gen.yaml.tmpl (postgres:16-alpine / tonic-only stack)
    And no 2.0.0 template is scaffolded
    And scaffoldable: false is still the effective setting
    And no scaffolder code change ships in this brick
```

---

## Anti-Hallucination Pass (Article III.4)

- **Plugins already shipped on 1.0.0 (central finding)** — plan §4.2 B.8.6's
  "extend buf.gen.yaml" is partially stale: `buf.build/connectrpc/go:v1.19.2`,
  `buf.build/bufbuild/es:v2.2.0`, `buf.build/connectrpc/dart:v1.0.0` ALREADY
  ship on the frozen 1.0.0 manifest (FR-T5-CC-001..003, t5-connect-codegen
  archived 2026-05-06). The real B.8.6 delta is the 2.0.0 versioned subtree +
  crate modernization + standard bump (proposal Ground-Truth). RECORDED
  prominently.
- **Rust crate versions deferred to verify-then-pin** — no version string for
  `connectrpc`, `connectrpc-build`, `buffa`, `buffa-types` (2.0.0 line) is
  asserted as registry-verified in this spec. The 0.5.x / 0.6.x observation from
  the proposal (2026-05-16) is a data point, NOT a pin (NFR-B86-006 / ADR-B86-001).
- **Connect-Dart plugin identity deferred to live verification** — Q-004 flags
  the plan naming drift (`protoc-gen-connect-dart-community` vs official
  `buf.build/connectrpc/dart:v1.0.0`). Whether the official plugin has advanced
  beyond v1.0.0 since 2026-05-06 is verified at `/forge:design` (FR-B86-004 /
  ADR-B86-003). Not guessed here.
- **2.0.0.yaml delivered-flip annotation shape** — the exact comment format is
  resolved at `/forge:design` by inspecting the live B.8.4 envoy-gateway annotation
  in 2.0.0.yaml (FR-B86-033). Not fabricated here.
- **transport.yaml schema_versions block shape** — the exact field name and
  nesting are resolved at `/forge:design` (ADR-B86-005 / FR-B86-021). This spec
  requires the 1.0.0 and 2.0.0 pin sets to be separately addressable; the shape
  is a design decision — **RESOLVED (ADR-B86-005): `codegen.versions_2_0_0:`
  sibling block, shipped in transport.yaml v1.3.0**.
- **b8-3 test coupling** — re-read of 2.0.0.yaml confirms the `connect-rpc`
  component uses `name`, `standard:`, `delivered_by`, `replaces` fields — none in
  the forbidden set `{version, pin, image}` (b8-3 T-012). A `# B.8.6 — delivered`
  comment is a YAML comment, not a scalar value — T-015 does not flag it. The
  `standard: transport.yaml` ref resolves (T-011). FR-B86-031 is grounded in
  direct re-read of the b8-3 test assertions.
- **Independent review required (NFR-B86-009)** — these specs MUST pass an
  independent reviewer before `/forge:design`. Not self-approved here.

## Open Questions

Tracked in `open-questions.md`: Q-001 (connectrpc crate target line — verify-then-
pin at implement → ADR-B86-001, open), Q-002 (2.0.0 subtree scope — buf.gen.yaml
+ README only, or also transport_connect.rs.tmpl → ADR-B86-002, open), Q-003 (Rust
S2S Connect client — land or re-defer to B.8.12 → ADR-B86-004, open), Q-004
(Connect-Dart plugin identity + version — live BSR verify at /forge:design →
ADR-B86-003, open).
