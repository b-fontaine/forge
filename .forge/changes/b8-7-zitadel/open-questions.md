# Open Questions — b8-7-zitadel

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
AUTHOR phase only: leanings recorded; NO Resolution sections here.
Resolutions are made at /forge:design by an INDEPENDENT reviewer + the
maintainer, NOT self-approved. All verify-then-pin items (Zitadel image tag,
Helm chart, bootstrap env-var names, Postgres compat matrix) are resolved LIVE
at /forge:design and re-verified at /forge:implement.
-->

## Resolution Log (/forge:design, 2026-06-02)

All five questions resolved at /forge:design (maintainer decisions, encoded in
`design.md` ADR-B87-001..006). The author flips them to answered here; an
INDEPENDENT reviewer ratifies before `/forge:plan` (NOT self-approved).
Maintainer decision pending INDEPENDENT reviewer ratification before /forge:plan.

The Q-001 + Q-004 final-re-verify (chart/image pins) and the Q-003 carried items
(FirstInstance chart wiring path, Admin API OIDC endpoint, JWT rotation cadence
URL) are LIVE steps at `/forge:implement`, not design ambiguities.

| Q | Decision | ADR |
|---|----------|-----|
| Q-001 | **(b) Chart-referenced hybrid** — lean falsified: manifests-only lean falsified by live initJob/setupJob evidence (P-09/P-10). Chart `10.0.2` / appVersion `v4.14.0` (chart-tested pair; v4.15.0 NOT chart-tested). Registry: `ghcr.io` (NOT docker.io, b8-coroot lesson). Subtree: 4 files (values-forge.yaml.tmpl + README.md.tmpl + docker-compose.fragment.yml.tmpl + bootstrap.md.tmpl). No kustomization.yaml.tmpl (chart-referenced posture). Final re-verify LIVE at /forge:implement. | ADR-B87-001 |
| Q-002 | **(a) Shared fsm-db** — Postgres 14+ requirement (P-04) satisfied by B.8.5 pg17. Dev: dedicated `zitadel` database + role on fsm-db, DSN via secretKeyRef; chart initJob handles schema/user creation K8s-side. T2/T3 prod: dedicated instance documented in README. No Bitnami postgresql subchart. | ADR-B87-002 |
| Q-003 | **Chart-native two-stage + Admin API recipe** — chart setupJob (P-10) IS the bootstrap mechanism (root tenant + machine user, Helm hook weight 2). FirstInstance env contract (P-11) drives setupJob with verified env-var names. OIDC client registration = documented post-bootstrap Admin API recipe in bootstrap.md.tmpl using machine-user PAT (endpoint verified at implement, NOT fabricated here). JWT signing-key rotation = Zitadel-managed automatic (bootstrap.md.tmpl + rotation cadence URL at implement). | ADR-B87-003 |
| Q-004 | **Login-UI topology resolved** — K8s: `login.enabled: true` (chart default, separate `ghcr.io/zitadel/zitadel-login:v4.14.0` Deployment, wired by chart). Dev compose: built-in login (single `fsm-zitadel` service, no separate login container in dev — deliberate dev/K8s difference, documented in README). Addressed together with Q-001 under ADR-B87-001. | ADR-B87-001 |
| Q-005 | **(a) Document-only** — lean confirmed. No SecurityPolicy manifest shipped. README cross-references B.8.4 Envoy templates and describes the delegation contract (`AT C4: Rel(envoy, zitadel, "OIDC")`). Explicit scope-out statement (FR-B87-064 verbatim). Fabricating Envoy API versions and Zitadel JWT issuer URLs would violate Article III.4 — deferred to B.8.10 design. | ADR-B87-006 |

---

## Q-001: Install source + version pins (Helm chart vs manifests; registry identity)

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B87-001 seed), `specs.md` FR-B87-001/041/042/070/071/075
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-7 specify pass)

### Question

The 2.0.0/infra/zitadel/ subtree vendors Zitadel K8s workload manifests (the
data-plane). The install source and version pins are unresolved:

- Does Zitadel publish an official Helm chart (`zitadel/zitadel-charts` or
  equivalent), and if so, is the pattern hybrid (control-plane via Helm, data-plane
  manifests vendored) analogous to B.8.4 Envoy Gateway? Or is the Helm chart the
  primary delivery and the brick vendors raw manifests extracted from the chart?
- What is the current stable Zitadel container image tag? Which registry is
  authoritative — `docker.io/zitadel/zitadel`, `ghcr.io/zitadel/zitadel`, or
  another? (The b8-coroot lesson: registries move — verify live, never fabricate.)
- Does the current Zitadel release ship the login UI as a **separate container**
  (v3 login-ui) or as a **monolith** (single container)? This directly affects the
  kustomization resource list and the compose fragment service count (Q-004 overlap).

`[NEEDS CLARIFICATION: Zitadel install source (Helm chart name + version vs raw
manifests), container image registry + tag, and runtime topology (monolith vs
split login-ui) — ALL verify-then-pin LIVE at /forge:design via official Zitadel
docs + live registry inspection. MUST NOT be fabricated at propose/specify
(Article III.4; b8-coroot lesson). → ADR-B87-001.]`

Three options to resolve at `/forge:design`:

- **(a) Manifests-only (no Helm chart vendored)** — Zitadel ships as a plain
  Deployment/Service/ConfigMap/Job; vendor the manifests directly; record only
  the container image pin in identity.yaml `versions:` map.
  **Lean here** (Zitadel has no CRD/controller half — the B.8.4 "control-plane
  chart" rationale may not apply; manifests-only is the smallest deliverable).
- **(b) Hybrid (Helm chart reference + vendored data-plane manifests)** — mirror
  B.8.4 exactly: record the Helm chart version in identity.yaml `versions:` +
  `pin_review_cadence:`, vendor the workload manifests separately.
- **(c) Helm chart only, no vendored manifests** — reference the upstream chart
  in the README install block; this brick ships no manifest templates. Lean
  against: loses the `N.N.N/` subtree convention and the hermetic harness
  grep-guard.

→ ADR-B87-001. Resolution at `/forge:design` by live Zitadel docs + registry
query + Context7 crate/chart docs.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(b) Chart-referenced hybrid** — lean **(a) manifests-only was
  FALSIFIED** by live evidence:
  1. The chart `10.0.2` carries initJob (Helm pre-install hook, wt=1) for DB
     schema/user creation and setupJob (Helm hook, wt=2) for first-org + machine-
     user bootstrap with K8s Secret generation (values.yaml P-09/P-10). This
     operator-grade machinery would require significant re-implementation if
     vendoring raw manifests.
  2. The login-UI split (`login.enabled: true` default, P-07) adds a separate
     `ghcr.io/zitadel/zitadel-login:v4.14.0` Deployment — wired automatically by
     the chart; manifests-only would duplicate this wiring.
  3. Chart `10.0.2` declares `appVersion: v4.14.0` (P-03) — the chart-tested
     pair. `v4.15.0` exists (P-01) but is NOT chart-tested.
  4. Registry: `ghcr.io` (GitHub Container Registry), NOT docker.io (P-08,
     b8-coroot lesson confirmed).
  The subtree delivers 4 files (values-forge.yaml.tmpl + README.md.tmpl +
  docker-compose.fragment.yml.tmpl + bootstrap.md.tmpl). No kustomization.yaml.tmpl
  (chart-referenced posture; no raw manifests vendored). identity.yaml `versions:`
  map records chart + image pins (ADR-B87-005). Final re-verify LIVE at
  `/forge:implement`.
- **Rationale**: (ADR-B87-001; evidence.md Finding 4 / P-01..P-03/P-07..P-14.)

---

## Q-002: Datastore topology — shared fsm-db vs dedicated Postgres instance

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B87-002 seed), `specs.md` FR-B87-030..037
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-7 specify pass)

### Question

Zitadel self-host requires a Postgres datastore. The 2.0.0 line already has the
B.8.5 `fsm-db` Postgres 17 (`pgvector/pgvector:0.8.2-pg17`) instance. Two
topologies are possible:

- Which Postgres major versions does Zitadel officially support? Is Postgres 17
  in its compat matrix? (The `pgvector/pgvector:0.8.2-pg17` image wraps Postgres
  17 — verify that Zitadel supports this major version live at design.)
- Should the dev compose fragment reuse the existing 2.0.0 `fsm-db` service
  (adding a dedicated `zitadel` database + role) or spin up a separate Postgres
  container for Zitadel?

`[NEEDS CLARIFICATION: Zitadel's supported Postgres version range and whether
the B.8.5 pgvector/pgvector:0.8.2-pg17 image satisfies the compat matrix —
verified LIVE at /forge:design via official Zitadel documentation. → ADR-B87-002.]`

Three topology options:

- **(a) Shared `fsm-db` (dedicated database/role)** — reuse the B.8.5 Postgres 17
  instance; create a dedicated `zitadel` database and `zitadel_user` role via an
  init asset. Simpler dev stack; T2/T3 production posture documented as
  dedicated-instance recommendation.
  **Lean here** (smallest dev-stack footprint; B.8.5 already supplies Postgres 17).
- **(b) Dedicated Postgres container for Zitadel** — a second Postgres service in
  the compose fragment; complete network isolation even in dev. Higher dev
  resource overhead but mirrors the T2/T3 prod topology more faithfully.
- **(c) Configurable (env-var toggle)** — template param selects shared vs
  dedicated. Adds complexity; out of character with Forge's declarative template
  philosophy.

→ ADR-B87-002. Resolution at `/forge:design` after live Zitadel Postgres compat
matrix check.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(a) Shared fsm-db** — lean confirmed. values.yaml lines 26–27
  (P-04): "ZITADEL requires **PostgreSQL 14+**". B.8.5 `pgvector/pgvector:0.8.2-pg17`
  (Postgres 17) satisfies 14+. Compatibility **confirmed**. Dev: dedicated
  `zitadel` database + `zitadel_user` role on fsm-db, DSN via `secretKeyRef`.
  Chart initJob (P-09) handles schema/user creation K8s-side. T2/T3 prod:
  dedicated Postgres instance with network isolation — documented in README.
  No Bitnami postgresql subchart (`postgresql.enabled: false` in values overlay).
- **Rationale**: (ADR-B87-002; evidence.md Finding 1 / P-04.)

---

## Q-003: Bootstrap mechanism — FIRSTINSTANCE env vs Admin-API Job vs CLI; masterkey; signing-key rotation

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B87-003 seed), `specs.md` FR-B87-020..027
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-7 specify pass)

### Question

Zitadel self-host requires bootstrapping: creating the root tenant (first
instance), registering an OIDC client app, and establishing a JWT signing-key
rotation posture. The exact mechanism is unresolved at specify time:

- Does Zitadel support a `ZITADEL_FIRSTINSTANCE_*` environment-variable contract
  that seeds the root organisation and machine user on first startup? What are
  the exact env-var names and required values? (NOT fabricated here — verified
  live via official Zitadel docs at design.)
- Is a separate Admin-API bootstrap Job (Kubernetes Job using the Zitadel Admin
  API) required for OIDC client app registration, or is this also coverable by
  env-var seeding?
- What are the masterkey constraints (minimum length, recommended generation
  command, storage pattern)?
- Is JWT signing-key rotation Zitadel-managed (automatic, internal) or an
  operator duty? What is the default rotation cadence per official docs?

`[NEEDS CLARIFICATION: Exact Zitadel bootstrap mechanism (env-var contract names,
Admin-API Job shape, CLI commands), masterkey length + generation, and JWT
signing-key rotation default — ALL resolved LIVE at /forge:design via official
Zitadel documentation (Context7 + zitadel.com/docs). Do NOT fabricate
ZITADEL_FIRSTINSTANCE_* variable names or masterkey constraints at specify phase
(Article III.4). → ADR-B87-003.]`

Three mechanism options:

- **(a) ZITADEL_FIRSTINSTANCE_* env contract** — seed root org + machine user
  via environment variables on first Zitadel startup; no separate Job.
- **(b) Admin-API Job for OIDC client** — even if tenant seeding uses env vars,
  the OIDC client registration may require an Admin-API call after Zitadel is
  ready (separate K8s Job with an init-container wait).
- **(c) zitadel CLI init command** — use the official Zitadel CLI.

→ ADR-B87-003. Resolution at `/forge:design` with live Zitadel official docs.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **Chart-native two-stage (setupJob + FirstInstance env contract)
  + documented Admin API recipe** — the chart setupJob (P-10, Helm hook weight 2)
  runs `zitadel setup` with the FirstInstance env-var contract (P-11), creating
  the first org, human admin, machine user (IAM_OWNER), and writing PAT to a
  K8s Secret. This IS the bootstrap — no separate K8s Job is authored. OIDC
  client registration = documented post-bootstrap Admin API recipe in
  `bootstrap.md.tmpl` using the machine-user PAT (endpoint verified at implement,
  NOT fabricated here). Masterkey: "Must be exactly 32 bytes" (P-06 verbatim),
  generation `tr -dc A-Za-z0-9 </dev/urandom | head -c 32`, pre-created K8s
  Secret via `masterkeySecretName`. JWT signing-key rotation: Zitadel-managed,
  automatic (documented in `bootstrap.md.tmpl`; rotation cadence URL at implement).
  Env-var names verified from live `steps.yaml` (P-11) — see evidence.md Finding 6.
  Carried verify-then-pin items at implement: FirstInstance chart wiring path,
  Admin API OIDC endpoint, JWT rotation cadence doc URL.
- **Rationale**: (ADR-B87-003; evidence.md Findings 3/5/6 / P-06/P-10/P-11.)

---

## Q-004: Runtime topology — monolith vs split login-UI container (v3 login-ui)

- **Status**: answered
- **Raised in**: `proposal.md` (Q-004 seed, ADR-B87-001/003 scope), `specs.md`
  FR-B87-001/002/071 (FR-B87-072 superseded by ADR-B87-001 — see specs.md Spec Delta)
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-7 specify pass)

### Question

The Zitadel project has evolved its login UI topology over time. At some point,
a v3 login-ui was separated into a distinct container alongside the main Zitadel
process. The current topology directly affects:

- The number of services in the compose fragment (one service vs two or more).
- The kustomization.yaml.tmpl `resources:` list (one Deployment vs two or more).
- The harness assertion count and the subtree file count (FR-B87-071 / FR-B87-072).

`[NEEDS CLARIFICATION: Does the current stable Zitadel release ship the login UI
as a separate container (v3 login-ui) requiring a distinct Deployment/Service, or
as a monolith (single Deployment)? How many services should the compose fragment
and kustomization declare? — resolved LIVE at /forge:design via official Zitadel
docs + live release notes. → ADR-B87-001 (topology section).]`

Two topology options:

- **(a) Monolith (single Deployment/Service)** — one `zitadel` Deployment and one
  Service; compose fragment has one `zitadel` service entry. Simpler subtree.
  **Lean here if the current stable release ships as a monolith** (verify live).
- **(b) Split (main + login-ui containers)** — two Deployments, two Services,
  two compose services.

→ ADR-B87-001 (topology subsection). Resolution at `/forge:design` by inspecting
values.yaml.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **Split in K8s (chart default), built-in in dev** — values.yaml
  line 363 (P-07): `login.enabled: true` default — separate `ghcr.io/zitadel/zitadel-login:v4.14.0`
  Deployment (confirmed P-13). The chart wires this topology automatically.
  K8s posture: login.enabled: true (retained in values-forge.yaml.tmpl — realistic
  topology). Dev compose: single `fsm-zitadel` service using built-in login
  (`login.enabled: false` equivalent — simpler dev stack, documented difference).
  No kustomization.yaml.tmpl (chart-referenced hybrid — ADR-B87-001 eliminates
  the need for a kustomization). Addressed together with Q-001 under ADR-B87-001.
- **Rationale**: (ADR-B87-001; evidence.md Finding 7 / P-07/P-13.)

---

## Q-005: Envoy OIDC delegation scope — document-only, or include a minimal SecurityPolicy example?

- **Status**: answered
- **Raised in**: `proposal.md` (ADR-B87-006 seed), `specs.md` FR-B87-063/064/066
- **Raised on**: 2026-06-02
- **Raised by**: author (b8-7 specify pass)

### Question

The B.8.7 proposal scopes the Envoy→Zitadel OIDC delegation as **document-only**
(ADR-B87-006 lean: defer SecurityPolicy/JWT-filter wiring to B.8.10/B.8.12).
The open question is whether a **minimal, non-wired SecurityPolicy example
manifest** should ship alongside the README documentation to help adopters
understand the intended delegation shape.

`[NEEDS CLARIFICATION: Should the 2.0.0/infra/zitadel/ subtree include a minimal
SecurityPolicy.yaml.tmpl example (commented out, marked NOT-FOR-PRODUCTION) in
addition to the README documentation of the delegation contract, or remain
documentation-only? → ADR-B87-006.]`

Two options:

- **(a) Documentation-only** — the README cross-references B.8.4 Envoy templates
  and describes the delegation contract (`AT C4: Rel(envoy, zitadel, "OIDC")`);
  no SecurityPolicy manifest ships.
  **Lean here** (smallest scope).
- **(b) Minimal commented example** — a `securitypolicy.example.yaml.tmpl`
  marked `# NOT FOR PRODUCTION — example only`.

→ ADR-B87-006. Resolution at `/forge:design`.

### Resolution

- **Resolved on**: 2026-06-02 (/forge:design — maintainer; INDEPENDENT reviewer
  ratifies before /forge:plan; status flips to answered)
- **Decision**: **(a) Document-only** — lean confirmed. No SecurityPolicy manifest
  shipped. A minimal example would require fabricating Envoy Gateway API versions
  and Zitadel JWT issuer URL patterns at B.8.7 design — Article III.4 bars this
  (b8-coroot lesson: fabricated API versions drift). The README explicitly states
  (FR-B87-064 verbatim): "The Envoy SecurityPolicy, JWTAuthn filter, and backend
  JWT validation middleware are NOT shipped in this brick. They are deferred to
  B.8.10 (Envoy OIDC wiring) and B.8.12 (E2E migration tests)."
- **Rationale**: (ADR-B87-006; Article III.4 anti-fabrication constraint.)
