# Open Questions — b8-6-connect-rpc

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
AUTHOR phase only: leanings recorded; resolutions are made at /forge:design by
an INDEPENDENT reviewer + the maintainer, NOT self-approved here. The concrete
Rust crate versions (Q-001) and Connect-Dart plugin version (Q-004) are
verify-then-pin at /forge:design (crates.io) and /forge:implement respectively.
-->

## Resolution Log (/forge:design, 2026-06-02)

All four questions resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B86-001..005). The author flips them to answered here; an
INDEPENDENT reviewer ratifies before `/forge:plan` (NOT self-approved). The
Q-001 final-re-verify and the Q-004 connect-go BSR check are LIVE steps at
`/forge:implement`, not design ambiguities.

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | 0.6.1 lockstep: `connectrpc = "=0.6.1"`, `connectrpc-build = "=0.6.1"`, `buffa = "=0.6.0"`, `buffa-types = "=0.6.0"` (buffa ^0.6 constraint from connectrpc 0.6.1 excludes 0.7.0; axum shape preserved on 0.6.x per P-07); final re-verify LIVE at /forge:implement | ADR-B86-001 |
| Q-002 | **(b)** Extended subtree — `2.0.0/shared/protos/buf.gen.yaml.tmpl` + `README.md.tmpl` + `2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl` + `2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`. 0.4.0 handler redesign falsifies the "buf.gen-only" minimal option; adapter variant REQUIRED | ADR-B86-002 |
| Q-003 | **(b)** Explicit re-defer to B.8.12 (E2E migration tests). No forcing evidence to land S2S client in B.8.6; non-trivial auth/TLS/retry scope. Chain: ADR-T5-003 → ADR-B86-004 → B.8.12 | ADR-B86-004 |
| Q-004 | Official plugin `buf.build/connectrpc/dart:v1.0.0` retained (pub.dev latest = 1.0.0, confirmed live P-08); plan naming `protoc-gen-connect-dart-community` definitively stale; gRPC-Web-via-Envoy fallback documented in README; connect-go BSR v1.20.0 check deferred to /forge:implement (P-11) | ADR-B86-003 |

---

## Q-001: connectrpc crate target line for 2.0.0 (verify-then-pin)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B86-001 seed), `specs.md` FR-B86-010..013
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-6 specify pass)

### Question

`transport.yaml` v1.2.0 pins the Rust Connect crate family at
`connectrpc = "=0.3.3"` (WAIVER — 13-day age at T5, pre-1.0) and
`buffa / buffa-types = "=0.3.0"` (CORRECTION — 0.3.3 was never published on
crates.io; series stops at 0.3.0) and `connectrpc-build = "=0.3.3"` (WAIVER).
The modernization to a newer line was explicitly deferred from T5.1.E to B.8
(plan lines 734-735). crates.io carried 0.5.x / 0.6.0 lines as of 2026-05-16
(proposal observation — NOT a pin, NOT verified at this phase). The 2.0.0 line
must pick up a modern, resolvable, integration-safe version.

`[NEEDS CLARIFICATION: What is the correct modern connectrpc / connectrpc-build /
buffa / buffa-types crate target for the 2.0.0 pin set? Resolved LIVE at
/forge:design via crates.io index query + Context7 crate docs. MUST NOT be
fabricated in propose/specify (Article III.4 / NFR-B86-006).]`

Three dimensions must be resolved together at `/forge:design`:

- **(a) Latest stable line** — query crates.io for the newest published
  `connectrpc` / `connectrpc-build` / `buffa` / `buffa-types` versions; check
  that `connectrpc`'s declared `buffa` dependency constraint resolves to a
  published exact pin (the T5.1.E lesson: `buffa = "=0.3.3"` was an error-of-fact
  because the series stopped at 0.3.0). **Lean: the newest line whose buffa compat
  matrix resolves live on crates.io.**
- **(b) axum integration shape** — verify `Router::into_axum_service()` (the
  FR-T5-CC-010 integration pattern) is still the correct surface on the modern
  line via Context7 crate docs. If the API surface changed incompatibly, the
  design must surface this as a constraint. **Lean: if the shape is unchanged,
  adopt the modern line; if incompatible, stay 0.3.3 with renewed WAIVER + dated
  re-review trigger.**
- **(c) connectrpc pre-1.0 vs post-1.0 status** — the crate was pre-1.0 at
  T5 (WAIVER). If the modern line has crossed 1.0.0, the WAIVER may no longer
  apply and the standard pin rationale changes.

→ ADR-B86-001. Resolution at `/forge:design` by independent reviewer + maintainer
with live crates.io evidence. The 1.0.0 pins (`=0.3.3` / `=0.3.0`) are
byte-unchanged regardless of the outcome (FR-B86-011).

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; Status flips to answered)
- **Decision**: **0.6.1 lockstep** — the 2.0.0 pin set is:
  - `connectrpc = "=0.6.1"` (max stable 2026-05-27, MSRV 1.88)
  - `connectrpc-build = "=0.6.1"` (exact lockstep with connectrpc)
  - `buffa = "=0.6.0"` (connectrpc 0.6.1 declares `buffa ^0.6`; resolves to
    `>=0.6.0, <0.7.0`; only 0.6.0 satisfies — 0.7.0 is OUT OF RANGE)
  - `buffa-types = "=0.6.0"` (same ^0.6 constraint)
  Final re-verify LIVE at `/forge:implement` per ADR-B86-001 clause.
- **Rationale**:
  - (a) crates.io P-01..P-04 confirm 0.6.1 is the current stable release.
  - (b) The upstream README (P-07) confirms the axum mount surface CHANGED on
    0.6.x (`ConnectRouter::new()` + `into_axum_service()`, not
    `into_axum_router()`); the `axum` feature is still required; the change is
    an added justification for the 2.0.0 adapter variant (ADR-B86-002). The
    CHANGELOG (P-06) confirms the 0.6.0 dispatcher breaking change does NOT
    affect build.rs users (connectrpc-build path).
  - (c) The crate is still pre-1.0 at 0.6.1 — but the T5 WAIVER was age-based
    (13-day); 0.6.1 is current stable with Anthropic OSS pedigree +
    ConnectRPC conformance suite. No new WAIVER required for the modernized pins.
  - The buffa/buffa-types 0.7.0 exclusion is a mathematical consequence of
    the semver constraint `^0.6`, not a judgment call (evidence.md Finding 1).

---

## Q-002: 2.0.0 subtree scope — buf.gen.yaml + README only, or also transport_connect.rs.tmpl?

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B86-002 seed), `specs.md` FR-B86-001/002, FR-B86-014
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-6 specify pass)

### Question

The minimum 2.0.0 transport subtree is `buf.gen.yaml.tmpl` + `README.md.tmpl`
(FR-B86-001). FR-T5-CC-010 shipped `transport_connect.rs.tmpl` on the 1.0.0 line
(the `connectrpc::Router::into_axum_service()` adapter in
`crates/grpc-api/src/`). If the modern crate line (Q-001) changes the adapter
API surface, a 2.0.0 variant `transport_connect.rs.tmpl` may be required. If the
adapter surface is unchanged, no additional file is needed.

`[NEEDS CLARIFICATION: Should the 2.0.0/shared/protos/ subtree ship only
buf.gen.yaml.tmpl + README.md.tmpl, or also a 2.0.0 transport_connect.rs.tmpl
variant? Decision depends on the modern crate line's adapter surface (Q-001).
Resolved at /forge:design once Q-001 is resolved via live crate docs.]`

- **(a) buf.gen.yaml.tmpl + README.md.tmpl only** — the minimum additive delta;
  `transport_connect.rs.tmpl` is path-stable if the adapter surface is unchanged.
  **Lean here** (smallest additive delta; the adapter template belongs under
  `backend/crates/grpc-api/`, not under `shared/protos/`; if the surface is
  unchanged the 1.0.0 template is already correct).
- **(b) + transport_connect.rs.tmpl under 2.0.0/backend/crates/grpc-api/src/** —
  only if the modern crate line (Q-001) changes the `into_axum_service()` surface
  incompatibly. The placement is `2.0.0/backend/` not `2.0.0/shared/protos/`.
- **(c) + Rust S2S Connect client template** — if ADR-B86-004 / Q-003 resolves
  to "land now", a client-side template also ships. Out of scope for (a).

→ ADR-B86-002. Resolution at `/forge:design` after Q-001 live crate docs review.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; Status flips to answered)
- **Decision**: **(b) Extended subtree** — four files:
  1. `2.0.0/shared/protos/buf.gen.yaml.tmpl`
  2. `2.0.0/shared/protos/README.md.tmpl`
  3. `2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl`
  4. `2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`
- **Rationale**: The CHANGELOG 0.4.0 entry (P-06, evidence.md Finding 2)
  documents a handler-signature redesign. Re-read of the 1.0.0
  `transport_connect.rs.tmpl` (2026-06-02) confirms it uses 0.3.x handler
  block shape — incompatible with 0.6.x at the handler-impl level. The adapter
  variant is REQUIRED (this is the central finding that falsifies option (a)).
  The `Cargo.toml.tmpl` variant is required to carry the 0.6.1/0.6.0 pins.
  The Rust S2S client (Q-003) is NOT included (ADR-B86-004 re-defer).
  (ADR-B86-002.)

---

## Q-003: Rust S2S Connect client — land in B.8.6 or re-defer to B.8.12?

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B86-004 seed), `specs.md` FR-B86-014
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-6 specify pass)

### Question

ADR-T5-003 (t5-connect-codegen design.md) deferred the Rust S2S Connect client
to B.8 (T6): "Demo-005 ships TS-only; Rust S2S Connect client deferred to B.8
(T6)." B.8.6 is the first B.8 brick touching the Rust Connect crate line. The
question is whether to land the S2S client template now or re-defer it.

`[NEEDS CLARIFICATION: Should the Rust S2S Connect client be (a) landed as a
minimal 2.0.0 template addition in B.8.6 if the modern crate line makes it
trivial, or (b) explicitly re-deferred to B.8.12 (E2E migration tests) with a
dated note? A silent omission (neither) is a constitutional violation (FR-B86-014).
Resolved at /forge:design with live crate docs (Q-001).]`

- **(a) Land now if trivial** — if the modern `connectrpc` crate (Q-001) makes a
  minimal `transport_connect_client.rs.tmpl` a straightforward addition (analogous
  to the server-side `transport_connect.rs.tmpl`), land it in B.8.6 as part of the
  2.0.0 template subtree under `2.0.0/backend/crates/grpc-api/src/`.
- **(b) Re-defer to B.8.12 (explicit)** — if the modern crate line requires
  non-trivial integration work (client configuration, auth, TLS, retry) that
  exceeds the B.8.6 scope, re-defer with a dated note in `design.md` and an
  updated ADR-T5-003 reference in `.forge/specs/connect-codegen.md`. **Lean here**
  (re-defer to B.8.12, which is the E2E migration convergence gate — better home
  for S2S client validation) — but only if the crate API review at design shows
  non-trivial work.
- **(c) Re-defer with a minimal stub** — ship a commented-out or `todo!()`-bearing
  stub to satisfy the "not silently omitted" gate, with the full implementation
  deferred to B.8.12.

→ ADR-B86-004. Resolution at `/forge:design` with live crate docs (depends on
Q-001 resolution).

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; Status flips to answered)
- **Decision**: **(b) Explicit re-defer to B.8.12** — the Rust S2S Connect client
  is NOT delivered in B.8.6. It is explicitly re-deferred to B.8.12 (E2E migration
  tests, dated 2026-06-02). This satisfies FR-B86-014 (explicit re-defer, not
  silent omission).
- **Rationale**: Wiring a correct Rust S2S client requires non-trivial decisions
  on authentication, TLS, deadline propagation, and retry policy — all concerns of
  B.8.12 (the zero-regression convergence gate). The scope of B.8.6 is already
  extended by ADR-B86-002 (four template files). No forcing evidence exists to land
  the S2S client here. Chain: ADR-T5-003 → ADR-B86-004 → B.8.12.
  (ADR-B86-004.)

---

## Q-004: Connect-Dart plugin identity and version (live BSR verification)

- **Status**: answered
- **Raised in**: `proposal.md` (Ground-Truth §, ADR-B86-003 seed), `specs.md`
  FR-B86-004, FR-B86-043
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-6 specify pass)

### Question

The plan §4.2 B.8.6 names `protoc-gen-connect-dart-community`. The frozen 1.0.0
`buf.gen.yaml.tmpl` ships `buf.build/connectrpc/dart:v1.0.0` — the OFFICIAL
ConnectRPC Dart plugin (replacing the abandoned `skadero/protoc-gen-connect-dart-
community`, per FR-T5-CC-003 / transport.yaml v1.1.0 header comment).

The 2.0.0 `buf.gen.yaml.tmpl` must carry the correct current official plugin
identity and version. The concrete BSR plugin version (`v1.0.0` or newer) must be
verified live at `/forge:design` against the Buf Schema Registry.

`[NEEDS CLARIFICATION: What is the current official Connect-Dart BSR plugin
identity and version? Verified LIVE at /forge:design against buf.build/connectrpc/dart.
MUST NOT be fabricated at propose/specify (Article III.4). The 1.0.0 frozen
manifest stays buf.build/connectrpc/dart:v1.0.0 regardless.]`

- This is a **verify-then-pin** item for the 2.0.0 manifest: the design phase
  queries `buf.build/connectrpc/dart` on BSR for the latest published version,
  documents the provenance (URL + access date, per the ADR-T5-002 plugin-version
  traceability pattern), and records the result in `design.md` ADR-B86-003. The
  implementation phase writes the verified version into the 2.0.0
  `buf.gen.yaml.tmpl`. **Lean (shape):** the official plugin identity
  `buf.build/connectrpc/dart` is correct (FR-T5-CC-003 confirmed this); only the
  version number may have advanced since `v1.0.0` (2026-05-06 ship date).
- **(a) `buf.build/connectrpc/dart` is still at `v1.0.0`** — the 2.0.0 manifest
  carries the same version as the 1.0.0 baseline; no advancement needed.
- **(b) `buf.build/connectrpc/dart` has advanced beyond `v1.0.0`** — the 2.0.0
  manifest carries the live verified version; the 1.0.0 frozen manifest stays
  `v1.0.0` byte-for-byte. **Lean here if the BSR confirms advancement.**
- **(c) Plugin identity has changed** — if the BSR plugin path has moved, the
  2.0.0 manifest uses the new authoritative identity; the plan naming drift
  (`protoc-gen-connect-dart-community` vs `connectrpc/dart`) is already resolved
  on the 1.0.0 line (FR-T5-CC-003); this item checks whether a further drift
  occurred since.

→ ADR-B86-003. Resolution at `/forge:design` by BSR query (live), documented in
`design.md` with provenance URL + access date. The 1.0.0 manifest is byte-frozen
regardless of the outcome (NFR-B86-002 / FR-B86-007).

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; Status flips to answered)
- **Decision**: **(a)** `buf.build/connectrpc/dart:v1.0.0` retained in the 2.0.0
  manifest. pub.dev confirms the `connectrpc` Dart package latest = **1.0.0**
  (P-08, 2026-06-02). No BSR version advancement since the 1.0.0 frozen pin.
  Plugin identity `buf.build/connectrpc/dart` is official and unchanged.
  Plan naming `protoc-gen-connect-dart-community` definitively stale (recorded,
  not mirrored). gRPC-Web-via-Envoy fallback documented in README (plan §13
  risk #1). connect-go BSR v1.20.0 availability check deferred to
  `/forge:implement` (P-11). (ADR-B86-003.)
- **Rationale**: pub.dev live check (P-08) is the authoritative proxy for the
  Dart Connect package version. The 1.0.0 baseline (`buf.build/connectrpc/dart:v1.0.0`)
  is still current — no advancement to pick up. The BSR plugin identity
  `buf.build/connectrpc/dart` was confirmed correct by FR-T5-CC-003 and is not
  disputed by the pub.dev check. The connect-go GitHub release v1.20.0 (P-11)
  requires a separate live BSR check to confirm remote-plugin availability — this
  is a `/forge:implement` gate, not a design-phase pin.
