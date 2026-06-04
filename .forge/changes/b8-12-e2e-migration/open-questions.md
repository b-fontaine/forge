# Open Questions — b8-12-e2e-migration

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Resolutions are made at /forge:design by an INDEPENDENT reviewer + the
maintainer, NOT self-approved. All author-phase leanings are recorded below
as candidate positions only; they do not constitute decisions.
-->

## Resolution Log (/forge:design, 2026-06-04)

Q-001..Q-005 resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B812-001..004). All five are leanings confirmed by LIVE
verification (connectrpc client README, Envoy v1.8.0 SecurityPolicy/JWT shape,
Zitadel OIDC discovery — evidence.md P-01..P-04). The resolutions are author
positions; they are **PENDING independent-reviewer ratification** before
`/forge:plan` proceeds (t5-2 self-validation lesson; b8-coroot inversion
lessons). The reviewer re-confirms the verify-then-pin LIVE items (NFR-B812-005:
connectrpc client API, Envoy Gateway SecurityPolicy API, Zitadel issuer) as part
of ratification — they are NOT self-ruled by the author.

| Q | Decision / Status | ADR |
|---|-------------------|-----|
| Q-001 | **(a) golden span-inventory SUPERSET as the binding L1 gate** — capture the 2.0.0 after-state golden, assert the 1.0.0 baseline 3-span set is a subset; phantom Flutter root absent from both goldens; reuse the t5-otel-live-run fake-OTLP + sanitised-golden pattern. Real p95/p99 = methodology DOC + opt-in `FORGE_B8_12_LIVE` leg (skip-pass). NO committed latency number (negative guard FR-B812-006/051). | ADR-B812-001 |
| Q-002 | **(a) land all three** — Envoy SecurityPolicy + JWT (`gateway.envoyproxy.io/v1alpha1`, `spec.jwt.providers[].remoteJWKS.backendRefs`→Backend, per v1.8.0 — MATCHES the existing gateway.yaml chart pin) + backend JWT validation middleware (tower layer). Envoy SecurityPolicy API is cleanly pinnable LIVE (evidence.md P-02/P-03), so the full scope lands. **Documented fallback (ADR-B87-006)**: if at implement the live SecurityPolicy API or the Zitadel jwks path cannot be cleanly pinned, fall back to middleware-only + a documented gateway stub (NO fabrication), recorded explicitly. | ADR-B812-002 |
| Q-003 | **(a) minimal correct client on the documented connectrpc 0.6.x client API** — `HttpClient::plaintext/with_tls`, `ClientConfig::new().with_default_timeout().with_default_header`, `<Svc>Client::new`, `greet`/`greet_with_options` + `CallOptions` (evidence.md P-01). auth = `authorization: Bearer` default-header; TLS via `with_tls()`; deadline via `with_default_timeout` + per-call `CallOptions`; retry documented. cargo-check gated L2 opt-in (`FORGE_E2E_TOOLCHAINS`). The connectrpc `client` Cargo feature flag is VERIFY-AT-IMPLEMENT (P-24). | ADR-B812-003 |
| Q-004 | **(a) tmpdir copy + `forge-migrate-flagship.sh --target`** — fresh `cp -r examples/forge-fsm-example/` into `mktemp -d` + `git init`; L1 = `--dry-run` plan assertion (exit 0) + exit-7 wrong-version negative; L2 opt-in (`FORGE_B8_12_LIVE`) = real Phase-2 overlay + additive assertions. Committed c1 stays 1.0.0 (git-clean after). The committed before/after artifact is the span-inventory YAML golden, not a project-tree snapshot. | ADR-B812-004 |
| Q-005 | **(a) extend `docs/MIGRATIONS.md`** — the latency methodology section homes in MIGRATIONS.md (the per-migration record), cross-referencing `docs/B8-BASELINE.md §6` (the procedure reference). No frozen baseline doc is touched; no numeric figure is committed. (Shared ADR slot with Q-001.) | ADR-B812-001 |

### specs.md `[NEEDS CLARIFICATION]` / Q→ADR anchor map

The design-deferred anchors in `specs.md` map to the ADRs below. `specs.md` is NOT
edited now — the marker-neutralisation happens at `/forge:implement` before the
status flip (b8-9/b8-10/b8-11 precedent). This table records the mapping for the
implementer.

| specs.md anchor | FR / location | Resolved by |
|-----------------|---------------|-------------|
| `[NEEDS CLARIFICATION: verify-then-pin LIVE at /forge:design (Q-003 → ADR-B812-003)]` | FR-B812-031, Anti-Halluc. pass (connectrpc client API) | ADR-B812-003 — connectrpc 0.6.x client API pinned (P-01); `client` feature flag VERIFY-AT-IMPLEMENT (P-24) |
| `[NEEDS CLARIFICATION: verify-then-pin LIVE at /forge:design (Q-002 → ADR-B812-002)]` | FR-B812-041 (Envoy SecurityPolicy apiVersion/kind) | ADR-B812-002 — `gateway.envoyproxy.io/v1alpha1` SecurityPolicy pinned (P-03) |
| `[NEEDS CLARIFICATION: verify-then-pin LIVE at /forge:design (Q-002 → ADR-B812-002)]` | FR-B812-043 (Zitadel OIDC discovery URL) | ADR-B812-002 — discovery URL `/.well-known/openid-configuration` pinned (P-04); exact jwks path VERIFY-AT-IMPLEMENT |

---

## Q-001: Before/after mechanism + methodology doc home — golden span-superset (hermetic, binding) vs any committed latency number; methodology doc location

- **Status**: **answered — (a) ratified, PENDING independent-reviewer confirmation (2026-06-04, /forge:design)** → ADR-B812-001
- **Raised in**: `proposal.md` (ADR-B812-001 seed), `specs.md` FR-B812-050
- **Raised on**: 2026-06-04
- **Raised by**: author (b8-12 specify pass)
- **Resolves at**: `/forge:design` → ADR-B812-001

### Context

The plan wording ("captures p95/p99 avant/après") conflicts with the hard fact that
`fsm-backend` is `image: scratch` (B8-BASELINE §3, FR-B8-1-012). ADR-B8-1-002
ratified "methodology + optional sample, NEVER committed live numbers." The
ratified honest form of the before/after gate is the span-inventory /
golden-span-tree regression (`.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`,
3 code-verified spans). Real p95/p99 measurement requires a real backend image —
it is not achievable from the unmodified c1 example.

A separate sub-question is where to home the methodology doc (FR-B812-050):
extend `docs/MIGRATIONS.md` with a B.8.12 section, or add a follow-on section
to `docs/B8-BASELINE.md`, or create a new `docs/B8-12-METHODOLOGY.md`.

### Options

- **(a) Golden span-superset (binding L1 gate) + methodology doc as MIGRATIONS.md extension
  (author recommendation)**: `.forge/changes/b8-12-e2e-migration/captures/
  full-stack-monorepo-2.0.0.span-inventory.yaml` is the committed after-state;
  the harness asserts the 3-span superset (`diff -q`, hermetic). The methodology
  doc extends `docs/MIGRATIONS.md` with a dedicated "Latency methodology (when a
  real backend image exists)" section, anchored to B.8.13 thresholds. No committed
  ms figures.
- **(b) Golden span-superset (binding L1 gate) + methodology doc as B8-BASELINE follow-on**:
  same gate mechanism, but the methodology doc is a new section appended to
  `docs/B8-BASELINE.md` (§9 or §10), keeping it adjacent to §6 (re-measurement
  methodology). Cross-referenced from MIGRATIONS.md.
- **(c) Golden span-superset (binding L1 gate) + standalone methodology doc
  `docs/B8-12-METHODOLOGY.md`**: dedicated file for discoverability; linked from
  both MIGRATIONS.md and B8-BASELINE.md.

**Author lean**: **(a)** — MIGRATIONS.md is the natural home for migration-phase
measurement guidance; §6 of B8-BASELINE.md is the procedure reference, not the
per-migration record. Extending MIGRATIONS.md avoids touching a frozen baseline
doc. **Reviewer decides.**

---

## Q-002: Envoy-OIDC scope — land SecurityPolicy + JWTAuthn + backend middleware all here, vs land middleware + defer gateway half if API unpinnable

- **Status**: **answered — (a) land all three, PENDING independent-reviewer confirmation (2026-06-04, /forge:design)** → ADR-B812-002
- **Raised in**: `proposal.md` (ADR-B812-002 seed), `specs.md` FR-B812-040..044
- **Raised on**: 2026-06-04
- **Raised by**: author (b8-12 specify pass)
- **Resolves at**: `/forge:design` → ADR-B812-002

### Context

ADR-B87-006 (b8-7-zitadel, 2026-06-02) explicitly deferred the Envoy SecurityPolicy,
JWTAuthn filter, and backend JWT validation middleware to B.8.12, and barred
fabricating the Envoy Gateway API version and Zitadel OIDC discovery URL patterns.
B.8.12 is the named landing point. The scope question is whether all three artifacts
(SecurityPolicy template, JWTAuthn filter template, backend JWT validation middleware
template) can be cleanly landed, or whether the gateway-side (SecurityPolicy +
JWTAuthn) should be deferred to a follow-on if the Envoy Gateway API cannot be
verify-then-pinned cleanly at design time.

### Options

- **(a) Land all three (SecurityPolicy + JWTAuthn + backend middleware) — full scope
  (author lean)**: if the Envoy Gateway SecurityPolicy `apiVersion`/`kind` and the
  `JWTAuthn` filter configuration shape can be cleanly pinned LIVE at `/forge:design`
  (via Envoy Gateway docs, GitHub Releases), land all three templates. This is the
  complete B.8.12 scope per the proposal and ADR-B87-006. Cross-reference identity.yaml
  v1.1.0 for Zitadel pins.
- **(b) Land backend middleware + defer gateway half to B.8.12-follow-on if API unpinnable**:
  if the Envoy Gateway API cannot be cleanly pinned live (e.g., API is in flux, no
  stable `apiVersion` confirmed), land only the backend JWT validation middleware
  template in B.8.12 and defer the SecurityPolicy + JWTAuthn templates to a
  B.8.12-follow-on change. This respects ADR-B87-006's anti-fabrication constraint
  (Article III.4 + b8-coroot lesson).

**Author lean**: **(a)** if the API is pinnable; **(b)** if the reviewer confirms
at design that the Envoy Gateway SecurityPolicy API is not yet stable enough to
pin (consistent with ADR-B87-006's concern). **Independent reviewer decides
after LIVE verification at /forge:design.**

---

## Q-003: Rust S2S Connect client surface — minimal `createClient`-equivalent on connectrpc 0.6.x; auth/TLS/deadline/retry posture; cargo-check tier

- **Status**: **answered — (a) minimal client + documented posture + L2 cargo-check, PENDING independent-reviewer confirmation (2026-06-04, /forge:design)** → ADR-B812-003
- **Raised in**: `proposal.md` (ADR-B812-003 seed), `specs.md` FR-B812-030..034
- **Raised on**: 2026-06-04
- **Raised by**: author (b8-12 specify pass)
- **Resolves at**: `/forge:design` → ADR-B812-003

### Context

ADR-B86-004 (b8-6-connect-rpc, 2026-06-02) explicitly re-deferred the Rust S2S
Connect client (`transport_connect_client.rs.tmpl`) from B.8.6 to B.8.12, citing
that wiring a correct Rust S2S client template requires non-trivial decisions on
authentication, TLS, deadline propagation, and retry policy. The connectrpc 0.6.x
crate provides client-side primitives; the exact API symbols (e.g., `ClientConfig`,
`CallOptions`, or their equivalents) must be verify-then-pin LIVE at design.
Transport.yaml `versions_2_0_0` pins (`connectrpc =0.6.1`, `buffa =0.6.0`) are
the authoritative pin source.

Sub-question: whether `cargo check` runs at L1 (no — CI has no cargo) vs L2
opt-in (`FORGE_E2E_TOOLCHAINS=1`, correct).

### Options

- **(a) Minimal client template + full auth/TLS/deadline/retry posture documented
  + cargo-check at L2 (author lean)**: deliver `transport_connect_client.rs.tmpl`
  with a minimal correct client construction on connectrpc 0.6.x (exact API
  verify-then-pin LIVE at design), inline comments documenting the auth/TLS/
  deadline/retry posture (e.g., Bearer token injection pattern, TLS config,
  context deadline forwarding, retry policy stub). `cargo check` gated behind
  `FORGE_E2E_TOOLCHAINS=1` — CI has no cargo toolchain. This satisfies ADR-B86-004
  ("correct convergence point for TLS, auth, retry, and deadline integration").
- **(b) Full working implementation + integration tests at L2**: deliver a
  fully-wired client with integration tests (requires a real Connect server endpoint
  in L2). More thorough but more complex harness. L2 still gated behind
  `FORGE_E2E_TOOLCHAINS=1`.
- **(c) Template stub only (documented-but-not-compiled)**: deliver a template with
  only inline comments and pseudocode stubs, no compilable Rust. Lighter scope but
  weaker quality gate.

**Author lean**: **(a)** — minimal correct + documented posture + L2 cargo-check.
This is the right quality bar for a 2.0.0 template: compilable, documented,
verifiable behind opt-in. **Reviewer decides after verifying connectrpc 0.6.x
client API LIVE at /forge:design.**

---

## Q-004: Migration target mechanics — tmpdir copy + `--target` flag; dry-run L1 vs real overlay L2

- **Status**: **answered — (a) tmpdir copy + `--target` + L1 dry-run + L2 real overlay, PENDING independent-reviewer confirmation (2026-06-04, /forge:design)** → ADR-B812-004
- **Raised in**: `proposal.md` (ADR-B812-004 seed), `specs.md` FR-B812-010..015
- **Raised on**: 2026-06-04
- **Raised by**: author (b8-12 specify pass)
- **Resolves at**: `/forge:design` → ADR-B812-004

### Context

The proposal establishes that "migrate c1 to 2.0.0" means invoking
`bin/forge-migrate-flagship.sh --target <tmpdir-copy-of-c1>` — NOT scaffolding a
new committed 2.0.0 example (2.0.0 is `scaffoldable: false` until B.8.14). The
committed `examples/forge-fsm-example/` stays at 1.0.0 (frozen reference). The
question is the exact mechanics: L1 = dry-run only; L2 = real Phase-2 overlay
(opt-in via `FORGE_B8_12_LIVE`).

A sub-question is whether the tmpdir approach (fresh `cp -r` on each test run)
is the right mechanism vs a committed snapshot of a migrated tree for golden
comparison purposes.

### Options

- **(a) Tmpdir copy + `--target` + L1 dry-run + L2 real overlay (author lean)**:
  each test run creates a fresh tmpdir via `cp -r examples/forge-fsm-example/`
  + `mktemp -d`. L1 runs `--dry-run` only (mutates nothing, fast, hermetic).
  L2 runs the real Phase-2 overlay and asserts the additive result. The committed
  c1 example is never touched. The 2.0.0 after-state golden (FR-B812-001) is the
  committed span-inventory YAML, not a committed migrated project tree.
- **(b) Committed snapshot of a migrated tree**: commit a snapshot of the migrated
  c1 project under `.forge/changes/b8-12-e2e-migration/migrated-snapshot/` and
  use `diff -r` for the after-state assertion. Richer golden but requires committing
  a large tree + keeping it in sync with the 2.0.0 template set.
- **(c) Tmpdir + shared cached copy across test runs**: cache the tmpdir across
  test invocations for speed. More complex cleanup, harder to guarantee isolation.

**Author lean**: **(a)** — tmpdir + dry-run L1 + real overlay L2. The span-
inventory YAML golden (FR-B812-001) is the committed before/after artifact, not
a full project snapshot. Simple, isolated, consistent with B.8.10's own harness
pattern. **Reviewer decides.**

---

## Q-005: Methodology doc home — extend `docs/MIGRATIONS.md` vs `docs/B8-BASELINE.md` follow-on vs standalone doc

- **Status**: **answered — (a) extend `docs/MIGRATIONS.md`, PENDING independent-reviewer confirmation (2026-06-04, /forge:design; shared ADR slot with Q-001)** → ADR-B812-001
- **Raised in**: `proposal.md` (seed), `specs.md` FR-B812-050
- **Raised on**: 2026-06-04
- **Raised by**: author (b8-12 specify pass)
- **Resolves at**: `/forge:design` → ADR-B812-001 (shared with Q-001)

### Context

FR-B812-050 requires a methodology doc describing how to measure p50/p95/p99 once
a real backend image exists, anchored to B.8.13 rollback thresholds. The doc must
NOT commit any latency number. The home of this doc affects discoverability and
coupling to the frozen `docs/B8-BASELINE.md`.

See Q-001 Options for the full option list (this Q is the sub-question of Q-001,
shared ADR slot ADR-B812-001).

**Author lean**: extend `docs/MIGRATIONS.md` (option (a) of Q-001) — the
measurement guidance is migration-phase context, not a frozen baseline fact. The
B8-BASELINE.md §6 re-measurement procedure is the reference; MIGRATIONS.md is
the per-migration record. **Reviewer decides alongside Q-001.**
