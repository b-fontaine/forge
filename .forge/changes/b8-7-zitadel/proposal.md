# Proposal: b8-7-zitadel

<!-- Created: 2026-06-02 -->
<!-- Schema: default -->
<!-- Audit: B.8.7 (docs/new-archetypes-plan.md §4.2 — Zitadel templates brick; ratified by ADR-007 ARCHITECTURE-TARGET.md) -->

## Problem

The 2.0.0 candidate schema (`.forge/schemas/full-stack-monorepo/2.0.0.yaml`,
B.8.3) declares Zitadel as the target identity component:

```yaml
  - name: zitadel
    role: identity
    replaces: implicit-auth
    delivered_by: B.8.7
    standard: identity.yaml  # default: zitadel
```

with the migration delta `implicit-auth → zitadel` (brick B.8.7, strategy
`additive-first`). The brick is **not delivered**: no identity subtree exists
under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` (only
`infra/k8s/envoy-gateway/` B.8.4, `infra/postgres/` B.8.5,
`shared/protos/` + `backend/crates/grpc-api/` B.8.6).

### GROUND-TRUTH FINDING (Article III.4) — this brick INTRODUCES identity, it migrates nothing

**Ground truth (re-read 2026-06-02, Article III.4):**

- The 1.0.0 flagship ships **no IdP, no OIDC client, no auth gate**.
  `docs/B8-BASELINE.md` §7 records the delta as `| implicit auth | Zitadel |
  B.8.7 |` and the §1 deployed-component matrix lists no identity component.
  The only identity surface is a **commented OIDC stub** in
  `.env.example.tmpl` (lines 20–24, "if the archetype adds auth").
  So "Zitadel migration auth" (plan §13 risk roll-up) is, for the flagship,
  an **introduction**, not a migration — the additive-first posture is
  structurally guaranteed.
- `identity.yaml` v1.0.0 (T.4 / J.5, ratifies ADR-007): `default: zitadel`,
  alternatives keycloak/authentik, `forbidden: firebase-auth + auth0-saas-us`,
  `compliance_tier_aware: true` (T3 self-host). Enforcement is OFF
  (`ci_blocking: false`, `linter_rule: null`) — documentation-only standard.
  It carries **no `versions:` map** — no chart/image pin source exists for
  Zitadel today (unlike `gateway.yaml` for Envoy).
- Compliance bindings already shipped: **J8-RULE-002** (`--eu-tier T3` +
  non-self-host Zitadel → `[REFUSAL:]` exit 3) and the T3 case-block in
  `bin/forge-init-fsm.sh:105-113` (grep guard on `infra/identity/` for
  auth0.com/okta.com/keycloak-cloud — "forward-looking guard that fires when
  adopters bring their own identity config files"). Tier matrix
  (`compliance-tiers.md:121`): Zitadel `⚠️ Cloud SaaS T1 / ✅ self-host T2 /
  ✅ self-host EU+SecNumCloud T3`.
- Conventions to mirror: B.8.4 hybrid control-plane/data-plane split
  (ADR-B84-003 — vendor data-plane manifests only, record pins in a root
  standard + README install block), `gateway.yaml` frontmatter model
  (`versions:` map + `pin_review_cadence:` ISO 8601 + dated expiry),
  B.8.5 self-validating compose fragment (loopback `127.0.0.1` binds per
  the B.8.8 Aegis dev posture), t5-otel-stack Aegis annotations
  (`forge.dev/aegis-audit: "required"` + `forge.dev/standard: "<file>@<ver>"`
  + minimal securityContext, no blanket `privileged: true`).
- Known upstream risks (AT:1089): Zitadel is AGPL (licensing attention
  required in adopter docs); its operator/Terraform tooling is less mature
  than Keycloak's — **the bootstrap script must do what an operator
  otherwise would** (root tenant, OIDC client app, signing-key rotation).
- Zitadel self-host **requires a Postgres datastore** — the B.8.5 brick
  (Postgres 17 + pgvector) is already in the 2.0.0 line (Q-002: shared
  `fsm-db` vs dedicated instance).
- All concrete versions (Helm chart, container image + registry, login-UI
  topology, bootstrap mechanism) are **verify-then-pin LIVE** at
  `/forge:design` and re-verified at `/forge:implement` — never fabricated
  here (t5.3.2 lesson: registries rot; b8-coroot lesson: hosts move).
- Stale plan cross-ref noted, non-blocking: plan:1318 (§0.5) conflates
  "B.8.7 ou équivalent" with the observability re-arch that actually
  landed as B.8.8 — flagged for the next doc pass, not this brick's scope.

## Solution

When built, the B.8.7 brick MUST:

1. Create the versioned identity subtree
   `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/`
   (K8s data-plane manifests + `kustomization.yaml.tmpl` + `README.md.tmpl`)
   following the B.8.4 hybrid split: vendor only the workload manifests;
   record the install path (Helm chart or raw manifests — Q-001) in the
   README + standard (→ ADR-B87-001).
2. Ship the **bootstrap mechanism** for: root tenant (first instance),
   OIDC client app registration, JWT signing-key rotation posture —
   exact mechanism (`ZITADEL_FIRSTINSTANCE_*` env contract vs Admin-API
   Job vs CLI) resolved live at design (→ ADR-B87-003, Q-003). Secrets
   (masterkey, admin credentials) are NEVER committed: K8s Secret
   references + `NEVER PUT SECRETS HERE` warnings (t5-otel-app
   precedent) + Aegis annotations on the bootstrap Job (→ ADR-B87-004).
3. Wire the datastore decision: Zitadel against the 2.0.0 Postgres
   (B.8.5) — shared `fsm-db` instance with dedicated database/role vs
   dedicated instance; dev-compose fragment
   `docker-compose.fragment.yml.tmpl` mirroring B.8.5 (loopback binds,
   self-validating `networks:`/`volumes:`) (→ ADR-B87-002, Q-002).
4. Bump `identity.yaml` additively v1.0.0 → v1.1.0: add the `versions:`
   map (chart/image pins per Q-001 live evidence) + `pin_review_cadence:`
   (mirror `gateway.yaml`), keep `default`/`alternatives`/`forbidden`
   byte-stable; append the REVIEW.md `Updated` ledger row (→ ADR-B87-005).
5. Document **T1 (Zitadel Cloud SaaS + DPA) vs T2/T3 (self-host EU
   strict)** in the subtree README, citing `compliance-tiers.md:121` and
   J8-RULE-002 (T3 refusal already enforced by `forge-init-fsm.sh`);
   include the **AGPL licensing note** (AT:1089).
6. Document the Envoy→Zitadel OIDC delegation posture (AT C4:
   `Rel(envoy, zitadel, "OIDC")`) as a README cross-reference to the
   B.8.4 templates; actual Envoy SecurityPolicy/JWT-filter wiring and
   backend JWT validation middleware are **out of scope** (deferred —
   Q-005, → ADR-B87-006).
7. Flip `2.0.0.yaml` `zitadel` to delivered per the B.8.4/B.8.6 precedent
   (comment-only annotation) without breaking `b8-3.test.sh` 17/17 nor
   `b8-3b.test.sh` 12/12.
8. Ship harness `.forge/scripts/tests/b8-7.test.sh` (~12 hermetic L1,
   mirror b8-4/b8-5/b8-6), register in `forge-ci.yml`, add the CHANGELOG
   `[Unreleased]` entry.
9. Run the full ~45-harness suite + gates before push
   (`full_harness_suite_before_push`; sibling version-pin scan for any
   harness grepping `identity.yaml`).

Decisions reserved for `/forge:design` (ADRs), leanings stated:

- **ADR-B87-001 — install source + pins.** Official Zitadel Helm chart
  (referenced README-side, B.8.4-style) vs fully vendored raw manifests.
  **Lean:** vendor the workload manifests (Zitadel is a plain
  Deployment/Service/ConfigMap/Job — no CRDs/controller, so the B.8.4
  "control-plane chart" half may collapse to manifests-only); record
  chart AND image pins live (registry identity verified — docker.io vs
  ghcr, the coroot lesson).
- **ADR-B87-002 — datastore.** **Lean:** reuse the 2.0.0 `fsm-db`
  Postgres 17 with a dedicated `zitadel` database + role for dev;
  document dedicated-instance separation as the T2/T3 prod posture.
  Verify live: Zitadel's supported Postgres versions vs the
  `pgvector/pgvector:0.8.2-pg17` image.
- **ADR-B87-003 — bootstrap mechanism.** **Lean:**
  `ZITADEL_FIRSTINSTANCE_*` env contract for root tenant + machine user;
  a bootstrap Job (Admin API) for the OIDC client app; signing-key
  rotation documented as Zitadel-managed with cadence noted. Verify the
  exact contract live (Zitadel docs via Context7/official docs).
- **ADR-B87-004 — secrets posture.** **Lean:** masterkey + admin secrets
  via K8s Secret refs generated at deploy time, never templated;
  `forge.dev/aegis-audit: "required"` + `forge.dev/standard:
  "identity.yaml@1.1.0"` annotations; minimal securityContext.
- **ADR-B87-005 — identity.yaml versioning.** **Lean:** additive 1.1.0
  (first `versions:` map — the standard becomes a pin source like
  `gateway.yaml`); no `breaking_change`; enforcement stays off
  (machine enforcement is a later brick, possibly with B.8.11/B.8.14).
- **ADR-B87-006 — Envoy OIDC wiring scope.** **Lean:** defer actual
  SecurityPolicy/JWT filter + backend middleware to B.8.10/B.8.12
  (E2E migration) — this brick is the IdP infrastructure; document the
  delegation contract only.

Release vehicle: **v0.4.0-rc.10**.

## Scope In

- `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/`
  (manifests + kustomization + README + bootstrap asset(s) +
  docker-compose fragment).
- `identity.yaml` v1.0.0 → v1.1.0 additive (+ REVIEW.md ledger row).
- `2.0.0.yaml` zitadel delivered-flip annotation.
- T1-vs-T2/T3 + AGPL + secrets documentation.
- Harness `b8-7.test.sh` + forge-ci.yml registration + CHANGELOG.

## Scope Out (Explicit Exclusions)

- **Any 1.0.0 touch** — templates, `schema.yaml`, snapshot, `.env.example`
  stub (frozen per B.8.2).
- **Envoy SecurityPolicy/JWT-filter wiring + backend Rust auth
  middleware** — deferred (ADR-B87-006); the C4 `Rel(envoy, zitadel)`
  contract is documented, not wired.
- **Frontend Flutter OIDC client** — mobile-only already has its own seam;
  flagship frontend auth is B.8.10/B.8.12 territory.
- **Keycloak/Authentik alternative templates** — `identity.yaml`
  alternatives stay documentation-only.
- **New Janus/CLI refusal logic** — J8-RULE-002 + the T3 guard already
  shipped (J.8); this brick only makes the guarded component deployable.
- **identity.yaml machine enforcement** (linter_rule) — stays off.
- **REST-bridge/Kong removal, schema promotion, Constitution amendment** —
  B.8.14.

## Impact

- **Users affected**: none until B.8.14 — 2.0.0 stays `scaffoldable: false`;
  1.0.0 adopters see zero change.
- **Technical impact**: new 2.0.0 subtree (~6-8 template files), 1 standard
  bump (additive, first identity pin source), 1 schema annotation flip,
  1 new harness. No production code.
- **Dependencies**: B.8.3 (candidate schema), B.8.4 (subtree + standard
  conventions, Envoy host), B.8.5 (Postgres datastore), T.4 (identity.yaml).

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: proposal precedes specs;
  no template before specs.md + design.md + tasks.md.
- **Article III.4 (Anti-Hallucination) — CENTRAL**: the "migration"
  premise was re-read against B8-BASELINE (introduction, not migration);
  every chart/image/bootstrap-contract claim is verify-then-pin LIVE at
  design + re-verified at implement; registry identity checked (coroot
  lesson); ambiguities carry Q-NNN markers.
- **Article IV (Delta-based)**: ADDED FRs only; `identity.yaml` bump
  additive with REVIEW.md ledger entry.
- **Article V (Compliance gate)**: harness + gates before any status flip;
  full suite before push; gates re-run POST-flip (b8-coroot lesson).
- **Article VIII.1 (Kong SHALL — IN FORCE, UNTOUCHED)**: additive brick;
  no gateway change.
- **Article VIII.5 (IaC)**: all deliverables are declarative manifests/
  fragments under version control.
- **Article XI.6 (Privacy)**: no PII flows introduced; bootstrap secrets
  posture documented (no secrets in repo — t5-otel-app precedent;
  XI.6 itself is AI/PII-scoped, cited for the data-minimization spirit).
- **Article XII (Governance)**: BDFL decision points recorded as ADRs at
  `/forge:design`.

## Open Questions (seed)

- **Q-001** — install source + pins: official Zitadel Helm chart
  (zitadel/zitadel-charts) vs vendored raw manifests; chart version +
  container image tag + registry identity (docker.io vs ghcr) — all
  verify-then-pin LIVE (→ ADR-B87-001; open).
- **Q-002** — datastore: shared 2.0.0 `fsm-db` (pgvector/pgvector:
  0.8.2-pg17) with dedicated database/role vs dedicated Postgres;
  Zitadel-supported Postgres versions live-checked (→ ADR-B87-002; open).
- **Q-003** — bootstrap contract: `ZITADEL_FIRSTINSTANCE_*` env vs
  Admin-API Job vs zitadel CLI for root tenant + OIDC client + machine
  user; JWT signing-key rotation: Zitadel-managed vs operator duty
  (→ ADR-B87-003; open).
- **Q-004** — runtime topology: does the current Zitadel line split the
  login UI into a separate container (v3 login-ui)? How many services in
  the dev fragment? (→ ADR-B87-001/003; open).
- **Q-005** — Envoy OIDC delegation: document-only here, or minimal
  SecurityPolicy example manifest? (→ ADR-B87-006; open, lean
  document-only).
