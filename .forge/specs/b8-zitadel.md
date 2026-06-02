# Spec: b8-zitadel

<!-- Audit: B.8.7 (b8-7-zitadel) -->
<!-- Source change : `.forge/changes/b8-7-zitadel/` (delta specs.md authoritative). -->

**Namespace** : `FR-B87-*` / `NFR-B87-*` / `ADR-B87-*`.
**Constitution** : v1.1.0, unchanged (no amendment). Article VIII.1 (Kong SHALL)
is **PRESERVED** — additive brick; Kong removal at B.8.14. Article VIII.5 (IaC)
is **SATISFIED** — all deliverables are declarative manifests/fragments under
version control. This change ships **no production code** in the running example
tree: it authors template files + standard bump + schema annotation + harness
only.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-
Hallucination — all Zitadel-specific contracts, image pins, Helm chart names,
env-var names, and bootstrap API endpoints are verify-then-pin LIVE at
`/forge:design` and re-verified at `/forge:implement`; Q-NNN markers used
throughout), IV (delta-based: all deliverables are additive; 1.0.0 frozen assets
untouched), V (harness + gates must pass before status flips), VIII.1 (Kong
SHALL — in force, PRESERVED), VIII.5 (IaC — declarative manifests only),
XI.6 (no PII flows introduced; secrets posture documented — no secret values
in repo), XII (BDFL decisions recorded as ADRs at `/forge:design`).

## Overview

B.8.7 delivers the **Zitadel identity brick**: a versioned subtree
`2.0.0/infra/zitadel/` (4 files: `values-forge.yaml.tmpl` + `README.md.tmpl` +
`docker-compose.fragment.yml.tmpl` + `bootstrap.md.tmpl`) using a
chart-referenced hybrid posture (chart `zitadel 10.0.2` / appVersion `v4.14.0`,
`ghcr.io/zitadel/zitadel:v4.14.0` — verify-then-pin LIVE + helm-template-validated
2026-06-02; lean manifests-only option **falsified** by live initJob/setupJob
evidence — ADR-B87-001), `identity.yaml` v1.0.0 → v1.1.0 additive (first
`versions:` map — standard becomes pin source like `gateway.yaml`), shared
`fsm-db` PG14+→pg17 (B.8.5 instance reused; ADR-B87-002), chart-native two-stage
bootstrap (`FirstInstance` + `setupJob`; `MachineKeyPath`/`PatPath`
CHART-MANAGED; Management API `POST /management/v1/projects/{project_id}/apps/oidc`
for OIDC client registration; ADR-B87-003), JWT rotation `KeyConfig 6h/30h` +
WebKeys v2 (fully automatic — no operator duty), secrets posture
`masterkeySecretName` 32-byte (injected via pre-created K8s Secret — never
committed), `identity.yaml` v1.1.0 first `versions:` map, `b8-7.test.sh` 12 L1
hermetic, `forge-ci.yml` registration, CHANGELOG entry, and Envoy-OIDC wiring
deferred to B.8.10/B.8.12 (ADR-B87-006). Independent review design round 2 +
final round 1 APPROVE. Archived 2026-06-02.

## GROUND-TRUTH FINDING (Article III.4) — this brick INTRODUCES identity, it migrates nothing

**Ground truth (re-read 2026-06-02, Article III.4):**

- The 1.0.0 flagship ships **no IdP, no OIDC client, no auth gate**.
  `docs/B8-BASELINE.md` §7 records the delta as `| implicit auth | Zitadel |
  B.8.7 |` and the deployed-component matrix lists no identity component. The
  only identity surface is a **commented OIDC stub** in `.env.example.tmpl`
  (lines 20–24, "if the archetype adds auth"). This brick is an **introduction**,
  not a migration — the additive-first posture is structurally guaranteed.
- `identity.yaml` v1.0.0 (T.4 / J.5): `default: zitadel`, alternatives
  keycloak/authentik, `forbidden: firebase-auth + auth0-saas-us`,
  `compliance_tier_aware: true`. Enforcement is OFF (`ci_blocking: false`,
  `linter_rule: null`) — documentation-only standard. It carried **no `versions:`
  map** — this brick adds the first Zitadel pin source (like `gateway.yaml`).
- Compliance bindings already shipped: **J8-RULE-002** (`--eu-tier T3` +
  non-self-host Zitadel → `[REFUSAL:]` exit 3) and the T3 case-block in
  `bin/forge-init-fsm.sh`. Tier matrix (`compliance-tiers.md:121`): Zitadel
  `⚠️ Cloud SaaS T1 / ✅ self-host T2 / ✅ self-host EU+SecNumCloud T3`.
- Zitadel is **AGPL**-licensed — adopter documentation notes this.
- Zitadel self-host **requires a Postgres datastore** (B.8.5 `fsm-db`).
- All concrete versions (Helm chart, container image + registry, login-UI
  topology, bootstrap env-var names, masterkey constraints) were **verify-then-pin
  LIVE** at `/forge:design` and re-verified at `/forge:implement`
  (b8-coroot + t5.3.2 lessons).
- Envoy→Zitadel OIDC delegation (`AT C4: Rel(envoy, zitadel, "OIDC")`) is
  **documented only** here; actual SecurityPolicy/JWT-filter wiring and backend
  auth middleware are deferred to B.8.10/B.8.12 (ADR-B87-006).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.2 B.8.7 (GROUND-TRUTH NOTE: introduction not migration; real delta is the 2.0.0 infra/zitadel/ subtree + bootstrap + datastore wire + identity.yaml v1.1.0) |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (B.8.3, candidate, `scaffoldable: false`) — component `zitadel` { role: identity, replaces: implicit-auth, delivered_by: B.8.7, standard: identity.yaml }; migration_delta { from: implicit-auth, to: zitadel, brick: B.8.7, strategy: additive-first } |
| **identity.yaml (observed)** | v1.0.0 (T.4) — `default: zitadel`, `forbidden: firebase-auth / auth0-saas-us`, `compliance_tier_aware: true`, `ci_blocking: false`, `linter_rule: null`. NO `versions:` map — this brick adds the first Zitadel pin source. |
| **gateway.yaml (observed)** | v1.0.0 (B.8.4) — frontmatter model mirrored: `versions:` map + `pin_review_cadence:` ISO 8601 + dated expiry. |
| **2.0.0.yaml (observed)** | `zitadel` component { role: identity, replaces: implicit-auth, delivered_by: B.8.7, standard: identity.yaml }; `implicit-auth → zitadel` migration_delta (strategy: additive-first). B.8.3 invariants: no inline pins, `standard:` refs only, `scaffoldable: false` until B.8.14. |
| **Subtree convention (B.8.4/B.8.5)** | `2.0.0/infra/k8s/envoy-gateway/` (kustomization + manifests + README) and `2.0.0/infra/postgres/` (compose fragment + init-SQL + README). B.8.7 mirrors this `N.N.N/` versioned-subtree pattern under `2.0.0/infra/zitadel/`. Repo-wide scans skip `N.N.N/` subtrees. |
| **Aegis annotation precedent (t5-otel-stack)** | `forge.dev/aegis-audit: "required"` + `forge.dev/standard: "<file>@<ver>"` on K8s manifests; minimal securityContext: `drop: [ALL]`, no blanket `privileged: true`. |
| **Secrets posture precedent** | B.8.5 compose fragment — no secret values committed; K8s Secret refs only; `NEVER PUT SECRETS HERE` warning in README (t5-otel-app precedent). |
| **B.8.3 invariants (binding)** | 1.0.0 stays frozen (B.8.2 sha256 guard); candidate stays `scaffoldable: false` until B.8.14; pins live in standards not in schema (ADR-B8-3-002). |
| **Test harness coupling** | `b8-3.test.sh` (17 L1): forbidden inline-pin keys `{version,pin,image}` (T-012), forbidden scalar `^\d+\.\d+` (T-015), every `standard:` ref must resolve (T-011), component must have `name` (T-010). `b8-3b.test.sh` (12 L1). Editing 2.0.0.yaml MUST keep both GREEN. |
| **Compliance** | `compliance-tiers.md:121` Zitadel row; `janus-orchestration-rules.md` J8-RULE-002; ADR-007 (ARCHITECTURE-TARGET.md). |
| **Release target** | v0.4.0-rc.10 |
| **Dependencies** | B.8.3 (candidate schema), B.8.4 (subtree convention + standard frontmatter model + Envoy host), B.8.5 (Postgres 17 datastore), T.4 (identity.yaml v1.0.0) |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — Versioned 2.0.0 identity subtree (FR-B87-001 → 010)

##### FR-B87-001 — 2.0.0/infra/zitadel/ subtree created
The brick MUST create the versioned identity subtree at
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/`
following the `N.N.N/` versioned-subtree convention established by B.8.4
(envoy-gateway) and B.8.5 (postgres). The subtree is exempt from repo-wide
scans that skip `N.N.N/` directories (ADR-B87-001). The exact file list is a
design-time decision per Q-001/Q-004 — this spec mandates the invariants below.

##### FR-B87-002 — values-forge.yaml.tmpl carries required Helm overlay keys
<!-- Modified at design-phase by ADR-B87-001 (chart-referenced pivot), 2026-06-02 -->
The subtree uses a **chart-referenced hybrid** (helm install + Forge values
overlay). No raw K8s manifests are vendored; accordingly `kustomization.yaml.tmpl`
is NOT delivered. Instead the subtree MUST contain `values-forge.yaml.tmpl` — a
Forge Helm values overlay that carries:
- `masterkeySecretName` reference (pre-created K8s Secret, 32-byte constraint)
- DSN `secretKeyRef` wiring (`ZITADEL_DATABASE_POSTGRES_DSN`)
- `login.enabled: true` (chart default, separate login-UI in K8s)
- `postgresql.enabled: false` (suppresses bundled Bitnami subchart; B.8.5 fsm-db
  is used instead — ADR-B87-002; also expressed as `--set postgresql.enabled=false`
  in the README helm install block)
- `firstInstance:` block with verified env-var mirrors (evidence.md P-11)
- pod-level Aegis annotations (`forge.dev/aegis-audit: "required"`,
  `forge.dev/standard: "identity.yaml@1.1.0"`)
- minimal `securityContext` (`allowPrivilegeEscalation: false`, `drop: [ALL]`)
- `NEVER PUT SECRETS HERE` comment block at the top of the file

Audit comment `# <!-- Audit: B.8.7 (b8-7-zitadel) -->` and
`# Standard: .forge/standards/identity.yaml` MUST appear at the top of
`values-forge.yaml.tmpl` (FR-B87-004 audit-header invariant is preserved).

##### FR-B87-003 — README.md.tmpl present and follows B.8.4/B.8.5 conventions
The subtree MUST contain `README.md.tmpl` documenting: (a) the delivery model
(chart-referenced hybrid — helm install + values overlay per ADR-B87-001), (b)
the `standard: identity.yaml` policy source reference, (c) the T1/T2/T3
compliance posture (§G6), (d) the AGPL licensing note (§G6), (e) the
Envoy→Zitadel OIDC delegation posture (§G6), (f) the `NEVER PUT SECRETS HERE`
warning (§G2). The README MUST carry an audit comment
`<!-- Audit: B.8.7 (b8-7-zitadel) -->`. Mirrors the B.8.4 `README.md.tmpl`
format (header, delivery model table, install block, resources table,
coexistence note).

##### FR-B87-004 — Audit comment headers on all template files
Every template file in the subtree MUST carry a top-of-file audit comment in
the form `# <!-- Audit: B.8.7 (b8-7-zitadel, FR-B87-NNN) -->` and a
`# Standard: .forge/standards/identity.yaml` line (mirrors the B.8.4
`gateway.yaml.tmpl` / `httproute.yaml.tmpl` format and the obi-daemonset.yaml.tmpl
Aegis precedent).

##### FR-B87-005 — Template variable conventions match sibling subtrees
All template variables in the Zitadel subtree MUST use the `<variable-name>`
convention (angle-bracket form) established by B.8.4/B.8.5 (e.g. `<project-name>`,
`<namespace>`). No deviating variable syntax is introduced. Template vars MUST
match the set used by sibling 2.0.0 subtrees where applicable (same
`<project-name>` for labels, same `<namespace>` for K8s namespace).

##### FR-B87-006 — Aegis annotations on workload template
Every workload manifest template in the subtree MUST carry Forge Aegis
annotations on its `metadata.annotations`:
```
forge.dev/aegis-audit: "required"
forge.dev/standard: "identity.yaml@1.1.0"
```
This mirrors the obi-daemonset.yaml.tmpl precedent (`forge.dev/aegis-audit: "required"`,
`forge.dev/standard: "observability.yaml@2.1.0"`) and the t5-otel-stack posture.
The standard reference uses the v1.1.0 version because this brick bumps
identity.yaml to v1.1.0 (§G4). Bootstrap Job manifests are included in this
requirement. **RESOLVED at /forge:design (ADR-B87-004):** Aegis annotations are
placed at pod-level in `values-forge.yaml.tmpl` (chart-native position confirmed
by helm-template validation 2026-06-02).

##### FR-B87-007 — Minimal securityContext, no blanket privileged
Every container spec in the subtree MUST declare a `securityContext` with at
minimum:
```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
```
No container in the Zitadel subtree MAY carry `privileged: true` as a blanket
flag (mirrors ADR-OTEL-004 / t5-otel-stack posture). **RESOLVED at /forge:design
(ADR-B87-004):** Zitadel requires no capabilities beyond a standard non-privileged
workload. The securityContext uses `runAsNonRoot: true`, `readOnlyRootFilesystem: true`,
`allowPrivilegeEscalation: false`, and `capabilities: drop: [ALL]` with no
additions. Placement is top-level chart values (helm-template-verified, evidence
Finding 8).

##### FR-B87-008 — Dev posture: loopback binds only (where applicable)
Any port binding in dev-oriented compose or manifest templates MUST use loopback
(`127.0.0.1:PORT:PORT`) and never `0.0.0.0` binds. Mirrors the B.8.5 postgres
fragment and the Aegis B.8.8 dev posture requirement (NFR-B87-002). This applies
to any compose service entries added by §G3.

##### FR-B87-009 — Subtree visible on disk; scaffoldable: false preserved
The 2.0.0/infra/zitadel/ subtree is an on-disk asset for the 2.0.0 candidate.
The candidate schema remains `scaffoldable: false` until B.8.14 (ADR-B8-3-003/005).
`forge init` still emits the flat 1.0.0 template tree with no identity component.
No scaffolder code change ships in this brick.

##### FR-B87-010 — 1.0.0 infra assets byte-unchanged
No file under `.forge/templates/archetypes/full-stack-monorepo/` outside the
`2.0.0/` versioned path MAY be modified by this brick (B.8.2 maintenance freeze).
The 1.0.0 `schema.yaml`, `docker-compose.dev.yml.tmpl`, `.env.example.tmpl`,
and all 1.0.0 template files MUST be byte-identical before and after. Any diff
touching a 1.0.0 asset is a constitutional violation.

---

#### Group 2 — Bootstrap mechanism (FR-B87-020 → 027)

##### FR-B87-020 — Bootstrap assets ship in the 2.0.0/infra/zitadel/ subtree
The brick MUST deliver the bootstrap mechanism for: (a) root tenant (first
instance), (b) OIDC client app registration, (c) JWT signing-key rotation
posture. **RESOLVED at /forge:design (ADR-B87-003):** Bootstrap is the
chart-native two-stage initJob + setupJob. The `FirstInstance` env-var contract
drives the setupJob. OIDC client app registration uses a post-bootstrap
Management API `POST /management/v1/projects/{project_id}/apps/oidc` call
documented in `bootstrap.md.tmpl`. No separate Job is authored.

##### FR-B87-021 — No secret value in any committed file
No committed template file in the subtree MAY contain an actual secret value —
no masterkey, no admin credential, no token, no password literal. All secrets
are expressed as K8s Secret references (`secretKeyRef:` / `envFrom: secretRef:`)
pointing to Secret names that are generated at deploy time and never templated
into the repository. This invariant is machine-verifiable: `grep -r
'secretKeyRef\|envFrom' 2.0.0/infra/zitadel/` MUST find only references, never
literal values alongside them (NFR-B87-004 — secrets posture).

##### FR-B87-022 — `NEVER PUT SECRETS HERE` warning verbatim in README and .env-adjacent docs
The `README.md.tmpl` MUST include the warning:

```
> **NEVER PUT SECRETS HERE.**
> The masterkey and admin credentials are K8s Secrets generated at deploy time.
> No secret value is committed to the repository. See the bootstrap section below.
```

verbatim (or equivalent wording that is equally prominent). Any `.env`-adjacent
documentation snippet in the subtree (e.g., sample env blocks for local dev)
MUST carry a similarly prominent warning. Mirrors the t5-otel-app precedent.

##### FR-B87-023 — Masterkey length/handling documented per live Zitadel docs
**RESOLVED at /forge:design (ADR-B87-003, evidence Finding 3):** Masterkey must
be exactly 32 bytes (printable ASCII recommended). Generated via
`openssl rand -base64 24 | tr -d '\n'` or equivalent. Injected via
`masterkeySecretName` referencing a pre-created K8s Secret; the masterkey value
is never placed in the values overlay file. The README documents this policy as
sourced from live Zitadel documentation (Article III.4).

##### FR-B87-024 — Bootstrap mechanism shape: chart-native two-stage
**RESOLVED at /forge:design (ADR-B87-003, evidence Findings 5–6):** Bootstrap is
the chart-native two-stage initJob + setupJob. The `FirstInstance` env-var
contract drives the setupJob: `ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH`,
`ZITADEL_FIRSTINSTANCE_PATPATH`, and `ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH`
are top-level fields under `FirstInstance:` (not org-nested). OIDC client app
registration uses a post-bootstrap Management API
`POST /projects/{project_id}/apps/oidc` call documented in `bootstrap.md.tmpl`.
No separate Job is authored. The mechanism:
- MUST create a root tenant and an OIDC client app without requiring any
  post-deploy manual console step.
- MUST NOT require storing an admin credential in a committed file.
- MUST document the JWT signing-key rotation cadence (Zitadel-managed).

##### FR-B87-025 — K8s Secret references use named Secrets only
Bootstrap Job and Deployment manifests MUST reference Zitadel secrets (masterkey,
admin credentials, DB connection string) via `secretKeyRef:` pointing to named
K8s Secrets. The Secret names MUST be documented as adopt-time-generated (not
fixed hardcoded names that imply a shipped secret). The README MUST include
a `kubectl create secret` example command with placeholder values, not real values.

##### FR-B87-026 — Bootstrap mechanism carries Aegis annotations
The chart-native bootstrap (initJob/setupJob controlled via `values-forge.yaml.tmpl`)
MUST carry the Forge Aegis annotations (FR-B87-006) and the minimal securityContext
(FR-B87-007) at pod level in the values overlay. Neither Job runs as root
(ADR-B87-004 confirmed: no additional capabilities required).

##### FR-B87-027 — JWT signing-key rotation posture documented
**RESOLVED at /forge:design (ADR-B87-003, evidence Finding 5):** JWT signing-key
rotation is Zitadel-managed and fully automatic — no operator rotation duty.
Rotation uses KeyConfig (6h activation / 30h expiry) and the WebKeys v2 API.
The README documents this posture and links to the upstream Zitadel key
management documentation.

---

#### Group 3 — Datastore wiring (FR-B87-030 → 037)

##### FR-B87-030 — Datastore decision: shared fsm-db
**RESOLVED at /forge:design (ADR-B87-002, evidence Finding 1):** Zitadel requires
PostgreSQL 14+. The B.8.5 `pgvector/pgvector:0.8.2-pg17` image satisfies this
requirement (17 ≥ 14, compatibility confirmed). The shared `fsm-db` pg17 instance
is reused; no dedicated Postgres instance is needed for dev posture.

##### FR-B87-031 — Dev compose fragment self-validates per B.8.5 pattern
The brick MUST ship `docker-compose.fragment.yml.tmpl` in `2.0.0/infra/zitadel/`
mirroring the B.8.5 postgres fragment structure:
- It MUST redeclare `networks:` and `volumes:` sections (self-validating
  fragment — the B.8.5 pattern; enables `docker compose -f fragment.yml config`
  to validate without the full stack context).
- It MUST use loopback binds (`127.0.0.1:PORT:PORT`) for any exposed dev port
  (FR-B87-008).
- It MUST NOT contain plaintext production credentials.
- It MUST carry an audit comment header (`# <!-- Audit: B.8.7 ... -->`) and a
  `NEVER PUT SECRETS HERE` warning in the comments.

##### FR-B87-032 — No plaintext production credentials in any template
No template file in `2.0.0/infra/zitadel/` MAY contain a plaintext production
credential, connection string with embedded password, or literal token. All
credential references MUST use environment variable substitution (`${VAR_NAME}`)
pointing to values sourced from `.env` (dev) or K8s Secrets (prod), never
hardcoded.

##### FR-B87-033 — Postgres version compatibility recorded from live evidence
**RESOLVED at /forge:design (ADR-B87-002, evidence Finding 1):** Zitadel requires
PostgreSQL 14+. The B.8.5 `pgvector/pgvector:0.8.2-pg17` image satisfies this
requirement. The shared `fsm-db` pg17 instance is reused. The README documents
this live-verified compatibility claim.

##### FR-B87-034 — Dedicated database/role documented for dev posture
The README MUST document: (a) the dev posture (dedicated `zitadel` database and
role within the 2.0.0 `fsm-db` instance per ADR-B87-002 lean), (b) the T2/T3
production posture recommendation (dedicated Postgres instance with network
isolation). The dev compose fragment reflects the chosen topology.

##### FR-B87-035 — Fragment image pin is verify-then-pin LIVE
**RESOLVED at /forge:design (ADR-B87-001, evidence Finding 4):** Canonical
registry is `ghcr.io` (not docker.io). Pinned pair:
`ghcr.io/zitadel/zitadel:v4.14.0` (chart 10.0.2 appVersion, manifest-verified
2026-06-02). `postgresql.enabled: false` is set; DSN injected via
`ZITADEL_DATABASE_POSTGRES_DSN` secretKeyRef (evidence Finding 2).

##### FR-B87-036 — init-SQL or DB-init asset ships if required by chosen topology
The compose fragment carries a database/role init comment or side-car pattern
creating the dedicated `zitadel` database and role. No hardcoded password — all
password references use `${ZITADEL_DB_PASSWORD}` or equivalent env-var form.

##### FR-B87-037 — Datastore fragment additive; 1.0.0 fsm-db byte-unchanged
The compose fragment is additive. The frozen 1.0.0 `docker-compose.dev.yml.tmpl`
`fsm-db` service (`postgres:16-alpine`) MUST be byte-unchanged (B.8.2 /
NFR-B87-003). The 2.0.0 fragment introduces a Zitadel service entry alongside
the B.8.5 `fsm-db` (postgres 17) without modifying any existing 1.0.0 file.

---

#### Group 4 — identity.yaml v1.0.0 → v1.1.0 additive bump (FR-B87-040 → 047)

##### FR-B87-040 — identity.yaml bumped additively v1.0.0 → v1.1.0
The brick MUST bump `.forge/standards/identity.yaml` from `version: "1.0.0"` to
`version: "1.1.0"` (additive — no breaking change; `default: zitadel`, `alternatives`,
`forbidden`, `compliance_tier_aware`, and `rationale` MUST be preserved verbatim —
byte-stable). `breaking_change: true` is NOT set (ADR-B87-005 lean). Machine
enforcement stays OFF (`ci_blocking: false`, `linter_rule: null` — these are
documentation-only; enforcement is a later brick, B.8.11/B.8.14 territory).

##### FR-B87-041 — First `versions:` map added to identity.yaml
**RESOLVED at /forge:design (ADR-B87-001 + ADR-B87-005, evidence Finding 4):**
The `versions:` map ships as: `zitadel_chart: "10.0.2"`, `zitadel: "v4.14.0"`,
`zitadel_login: "v4.14.0"` (all `ghcr.io`, manifest-verified 2026-06-02).
`pin_review_cadence:` is added per ADR-B87-005. Shipped in identity.yaml v1.1.0.

##### FR-B87-042 — `pin_review_cadence:` field added, ISO 8601
The v1.1.0 identity.yaml MUST add `pin_review_cadence:` mirroring the
`gateway.yaml` pattern. The cadence values (P30D for container image, P12M for
chart) use ISO 8601 duration format, resolved at `/forge:design` based on
Zitadel's upstream release velocity.

##### FR-B87-043 — `default`/`alternatives`/`forbidden` byte-stable through v1.1.0
The v1.1.0 bump MUST NOT change `default: zitadel`, `alternatives: [keycloak,
authentik]`, or `forbidden: [firebase-auth, auth0-saas-us]`. These fields are
byte-identical in v1.1.0 to v1.0.0 (additive-only bump per Article IV).

##### FR-B87-044 — REVIEW.md ledger receives a B.8.7 entry
`.forge/standards/REVIEW.md` MUST receive an append-only `Updated` entry for
`identity.yaml v1.1.0`, dated 2026-06-02, with a one-line description (additive:
first `versions:` map + `pin_review_cadence:` — Zitadel becomes a pin source like
`gateway.yaml`). Mirrors the B.8.4 `gateway.yaml` and B.8.6 `transport.yaml`
REVIEW.md precedents (Article XII append-only ledger).

##### FR-B87-045 — identity.yaml v1.1.0 passes J.7 validate-standards-yaml.sh
After the v1.1.0 edit, `bin/validate-standards-yaml.sh` (J.7) MUST pass in both
single-file mode and directory mode. The MANDATORY `REVIEW.md` row for
`identity.yaml | 1.1.0` (FR-J7-023 coupling) is satisfied by FR-B87-044.
The updated `expires_at:` and header comment MUST reflect v1.1.0 and the B.8.7
change date.

##### FR-B87-046 — identity.yaml v1.1.0 `last_reviewed` and `expires_at` updated
The v1.1.0 bump MUST update `last_reviewed: 2026-06-02` and `expires_at` to 12
months from last_reviewed (2027-06-02), mirroring the `gateway.yaml` dated-expiry
pattern. Setting a dated `expires_at:` in the v1.1.0 edit requires
`exception_constitutional: false` (FR-J7-020 coupling — consistent with
`gateway.yaml`).

##### FR-B87-047 — No WAIVER required for identity.yaml bump
The v1.0.0 → v1.1.0 bump is purely additive (first `versions:` map +
`pin_review_cadence:` + date updates; no semantic field changed; `breaking_change`
is not set). No WAIVER commentary is needed for the bump itself.

---

#### Group 5 — 2.0.0.yaml delivered-flip annotation (FR-B87-050 → 054)

##### FR-B87-050 — zitadel component annotated `# B.8.7 — delivered`
The `2.0.0.yaml` `zitadel` component MUST receive an inline comment
`# B.8.7 — delivered` on or adjacent to the `delivered_by: B.8.7` line,
following the B.8.4 precedent (envoy-gateway) and B.8.6 precedent
(connect-rpc). The `standard: identity.yaml` reference-only annotation
MUST be preserved (not replaced by an inline pin — ADR-B8-3-002).

##### FR-B87-051 — Delivered annotation MUST NOT break b8-3 / b8-3b
The annotation MUST NOT introduce a forbidden inline-pin key (`version`/`pin`/
`image` — b8-3 T-012) and MUST NOT add a component scalar value matching
`^\d+\.\d+` (b8-3 T-015). The `zitadel` `name`, `standard: identity.yaml`
ref (T-010/T-011), `role: identity`, `replaces: implicit-auth`, and the
`implicit-auth → zitadel` migration_delta (strategy: additive-first) MUST
remain intact. After the annotation, `b8-3.test.sh` (17 L1) and
`b8-3b.test.sh` (12 L1) MUST stay GREEN.

##### FR-B87-052 — implicit-auth NOT removed from 2.0.0.yaml
The `implicit-auth → zitadel` migration delta MUST remain intact with
`strategy: additive-first`. The additive-first posture means the old
implicit-auth "component" (which was never a real deployed component — it was
absent in 1.0.0, hence "introduction" in the Ground-Truth) is retained in the
migration_delta record. No `from: implicit-auth` row is deleted by this brick.

##### FR-B87-053 — Annotation shape mirrors B.8.4/B.8.6 delivered-flip pattern
The inline comment style (`# B.8.7 — delivered`) MUST mirror the envoy-gateway
and connect-rpc delivered-flip annotations in `2.0.0.yaml` so that the candidate
schema is consistently annotated across delivered bricks. Formatting (spacing,
em-dash) confirmed at `/forge:design` by inspecting the live B.8.4/B.8.6
annotations.

##### FR-B87-054 — 2.0.0.yaml edit satisfies all existing b8-3 / b8-3b test assertions
The edit MUST be regression-tested by running `b8-3.test.sh` (17/17) and
`b8-3b.test.sh` (12/12) after the annotation. Both MUST exit 0. The b8-7
harness MUST include an exit-code coupling guard (mirroring b8-5 T-009 /
b8-6 FR-B86-058).

---

#### Group 6 — T1/T2/T3 + AGPL + Envoy-OIDC-delegation documentation (FR-B87-060 → 066)

##### FR-B87-060 — T1 vs T2/T3 compliance posture documented in the subtree README
The `2.0.0/infra/zitadel/README.md.tmpl` MUST include a section documenting:
- **T1** (Zitadel Cloud SaaS with a Data Processing Agreement): acceptable for
  non-EU-strict deployments; `⚠️ Cloud SaaS T1` per `compliance-tiers.md:121`.
- **T2** (self-hosted EU): Zitadel self-hosted on EU infrastructure; `✅ self-host T2`.
- **T3** (self-hosted EU + SecNumCloud): Zitadel self-hosted on
  OVHcloud/Scaleway/Outscale; `✅ self-host EU+SecNumCloud T3`.
The section MUST cite `compliance-tiers.md:121` (the verbatim Zitadel tier row)
and reference J8-RULE-002 (`janus-orchestration-rules.md`) which already enforces
the T3 refusal at scaffold time. The section MUST reference ADR-007
(ARCHITECTURE-TARGET.md).

##### FR-B87-061 — J8-RULE-002 cross-reference in the README
The README MUST explicitly note that the J8-RULE-002 refusal (`--eu-tier T3` +
non-self-host Zitadel → exit 3) is already enforced by `forge-init-fsm.sh` and
the Janus orchestration rules. This brick only makes the guarded component
deployable — no new refusal logic is added (Scope Out).

##### FR-B87-062 — AGPL licensing note in the README
The README MUST include a prominently placed AGPL licensing note, e.g.:

> **License note**: Zitadel is licensed under the GNU Affero General Public
> License v3 (AGPL-3.0). Review your organisation's open-source policy and
> any applicable DPA requirements before deploying Zitadel in a commercial
> product. See [zitadel.com](https://zitadel.com) for commercial licensing options.

The exact wording MUST convey: AGPL-3.0, commercial licensing note, and a
pointer to Zitadel's official site (AT:1089).

##### FR-B87-063 — Envoy→Zitadel OIDC delegation posture documented
The README MUST document the delegation contract: Envoy Gateway (B.8.4 templates)
delegates AuthN to Zitadel via OIDC (`AT C4: Rel(envoy, zitadel, "OIDC")`).
The section MUST cross-reference the B.8.4 Envoy template path
`2.0.0/infra/k8s/envoy-gateway/`. The section MUST explicitly state that actual
Envoy SecurityPolicy/JWT-filter wiring and backend Rust auth middleware are
**out of scope for this brick** and are deferred to B.8.10/B.8.12 (ADR-B87-006).

##### FR-B87-064 — Wiring exclusion stated explicitly
The README MUST state verbatim (or equivalent): "The Envoy SecurityPolicy,
JWTAuthn filter, and backend JWT validation middleware are NOT shipped in this
brick. They are deferred to B.8.10 (Envoy OIDC wiring) and B.8.12 (E2E
migration tests)." This prevents implementers from accidentally landing
wiring code in B.8.7 scope.

##### FR-B87-065 — Documentation is self-consistent with the compliance-tiers.md table
The README MUST NOT contradict the Zitadel tier row in `compliance-tiers.md:121`
(`⚠️ Cloud SaaS T1 / ✅ self-host T2 / ✅ self-host EU+SecNumCloud T3`). If the
README describes a specific deployment topology, it MUST correctly classify it
under the tier matrix.

##### FR-B87-066 — Scope-out items explicitly named in the README
The README MUST include a "Scope out (this brick)" section listing: Envoy
SecurityPolicy/JWT-filter wiring (→ B.8.10), backend Rust auth middleware (→ B.8.12),
Flutter OIDC client (→ B.8.10/B.8.12), Keycloak/Authentik alternative templates
(identity.yaml alternatives stay documentation-only), identity.yaml machine
enforcement (`linter_rule` — later brick).

---

#### Group 7 — Harness b8-7.test.sh + forge-ci.yml + CHANGELOG (FR-B87-070 → 079)

##### FR-B87-070 — Harness file created, hermetic, ≤ 2 s L1, registered
The brick MUST ship `.forge/scripts/tests/b8-7.test.sh` with: `--level` flag,
`source _helpers.sh`, `run_test`, `print_summary` (mirroring b8-4 / b8-5 / b8-6
harness structure). L1 wall-clock budget **≤ 2 s** (NFR-B87-001). Zero network
or Docker calls at L1. MUST be registered as a one-line entry
`"b8-7.test.sh --level 1"` in `.github/workflows/forge-ci.yml` after the
`b8-6.test.sh` line. **DELIVERED: 12 L1 tests, all GREEN.**

##### FR-B87-071 — Harness asserts 2.0.0/infra/zitadel/ subtree exists (four files)
<!-- Modified at design-phase by ADR-B87-001 (chart-referenced pivot), 2026-06-02 -->
The harness MUST assert the following **four files** exist (chart-referenced
posture — no kustomization, no raw manifests):
1. `2.0.0/infra/zitadel/values-forge.yaml.tmpl`
2. `2.0.0/infra/zitadel/README.md.tmpl`
3. `2.0.0/infra/zitadel/docker-compose.fragment.yml.tmpl`
4. `2.0.0/infra/zitadel/bootstrap.md.tmpl`

A missing required file is a FAIL. No additional manifest files are asserted
(none are vendored in the chart-referenced hybrid).

##### FR-B87-072 — Harness asserts values-forge.yaml.tmpl key sentinels present
<!-- Modified at design-phase by ADR-B87-001 (chart-referenced pivot), 2026-06-02 -->
The harness MUST assert that `values-forge.yaml.tmpl` contains the key sentinel
**`masterkeySecretName`** AND the Aegis annotation sentinel
`forge.dev/aegis-audit` — confirming the values overlay carries the required
secrets-posture and Aegis wiring (replaces the kustomization-completeness check
with a values-overlay key-presence check).

##### FR-B87-073 — Harness asserts no secret values committed
The harness MUST assert that no file in `2.0.0/infra/zitadel/` contains a
literal secret value. The test uses grep patterns to detect: hardcoded passwords,
literal API tokens of known formats, and any line matching
`password: [^${\[NEVER\]'"'"'(]` that is not an env-var reference or a warning
string. A match is a FAIL (NFR-B87-004 — secrets posture invariant).

##### FR-B87-074 — Harness asserts Aegis annotations present on workload manifests
The harness MUST assert that `forge.dev/aegis-audit: "required"` and
`forge.dev/standard: "identity.yaml@1.1.0"` appear in at least one template
file in the subtree (FR-B87-006). Mirrors b8-5's observability.yaml
annotation check.

##### FR-B87-075 — Harness asserts identity.yaml at v1.1.0 + versions: block present
The harness MUST assert `identity.yaml` `version:` field is `"1.1.0"` and that
the file contains a `versions:` block with at least one key (FR-B87-041 /
FR-B87-040). Mirrors b8-6 FR-B86-054 (transport.yaml version assertion).

##### FR-B87-076 — Harness asserts REVIEW.md B.8.7 entry present
The harness MUST assert `.forge/standards/REVIEW.md` contains a row referencing
`identity.yaml` and `1.1.0` (FR-B87-044). Mirrors b8-5 T-007 / b8-6 FR-B86-056.

##### FR-B87-077 — Harness asserts 2.0.0.yaml zitadel delivered annotation
The harness MUST assert the `2.0.0.yaml` `zitadel` component carries the
`# B.8.7 — delivered` annotation comment and that `standard: identity.yaml`
still resolves (FR-B87-050/051). The `implicit-auth → zitadel` migration_delta
MUST still be present with `strategy: additive-first` (FR-B87-052).

##### FR-B87-078 — Harness coupling guard: b8-3 (17/17) + b8-3b (12/12) GREEN
The harness MUST run `b8-3.test.sh --level 1` and `b8-3b.test.sh --level 1` as
exit-code-only coupling guards (the b8-4 T-012 / b8-5 T-009 strategy). Both
MUST exit 0 for the b8-7 harness to PASS. Any breakage of the existing b8-3 or
b8-3b gate is a b8-7 FAIL.

##### FR-B87-079 — CHANGELOG [Unreleased] entry added
The brick MUST add a `## [Unreleased]` section entry in `CHANGELOG.md`
summarising the B.8.7 deliverables (2.0.0/infra/zitadel/ subtree, identity.yaml
v1.1.0, 2.0.0.yaml annotation, harness). Mirrors the B.8.4 / B.8.5 / B.8.6
CHANGELOG precedent. **DELIVERED.**

---

### Non-Functional Requirements

##### NFR-B87-001 — Harness L1 ≤ 2 s wall-clock (hermetic)
The `b8-7.test.sh` L1 harness wall-clock MUST be ≤ **2 s** on the CI runner (no
network, no Docker, no cargo build). All assertions are grep / stat / file-exists
operations. ~12 test cases at L1 (mirroring b8-5 12 L1 / b8-6 12 L1 pattern).

##### NFR-B87-002 — Frozen 1.0.0 byte-identity preserved
The frozen `schema.yaml` (1.0.0), the flat 1.0.0 template tree (including
`docker-compose.dev.yml.tmpl`, `.env.example.tmpl`, and all 1.0.0 template
assets), and `full-stack-monorepo/1.0.0.tar.gz` MUST be byte-unchanged by this
brick AND by the downstream implementation. Respects B.8.2 maintenance freeze +
sha256 guard (B.8.3 invariant).

##### NFR-B87-003 — b8-3.test.sh (17/17) + b8-3b.test.sh (12/12) stay GREEN
All existing B.8.3 schema gates MUST stay GREEN after every file touched by this
brick. A FAIL in either harness constitutes a B.8.7 constitutional violation
(Article V.2). The b8-7 harness enforces this as a coupling guard (FR-B87-078).

##### NFR-B87-004 — No secret material anywhere in the repo
No committed file introduced or modified by this brick MAY contain a plaintext
secret value (masterkey, password, token, API key). Machine-verifiable grep
guard enforced by FR-B87-073 in the harness. This is a hard stop: a secret
found in a template is a blocking violation (Article XI.6 spirit; t5-otel-app
precedent).

##### NFR-B87-005 — Full ~46-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~46 harnesses in
`.forge/scripts/tests/`) MUST pass (the `full_harness_suite_before_push`
memory lesson — sibling scans can break silently). This includes `b8-3`,
`b8-3b`, `b8-4`, `b8-5`, `b8-6`, `b8-7`, and any harness whose repo-wide scan
could be affected by the new `identity.yaml` version bump or the
`2.0.0/infra/zitadel/` subtree. **DELIVERED: full suite 46/46 GREEN.**

##### NFR-B87-006 — Zero new external dependencies
This brick MUST NOT introduce any new external dependency (no new npm package,
no new crate, no new binary). The 2.0.0 template subtree, the standard bump,
and the harness are file-only changes. The identity.yaml `versions:` block
records pins as documentation; it does not introduce a new build-time dep.

##### NFR-B87-007 — Verify-then-pin LIVE at /forge:design and re-verify at /forge:implement
All Zitadel version pins (image tag, Helm chart version, registry identity) MUST
be resolved from live registries at `/forge:design` (Q-001, ADR-B87-001) and
re-verified at `/forge:implement` (b8-coroot lesson — hosts move between design
and implement). **DELIVERED: `ghcr.io/zitadel/zitadel:v4.14.0` + chart 10.0.2
manifest-verified 2026-06-02.**

##### NFR-B87-008 — Article VIII.1 preserved (Kong SHALL — UNTOUCHED)
This brick is additive. Kong removal and any VIII.1 amendment are B.8.14. The
2.0.0.yaml `zitadel` delivered-flip does NOT authorize removing Kong from any
live stack. The candidate remains `scaffoldable: false`.

##### NFR-B87-009 — Independent review required before /forge:plan
These specs MUST pass an **independent reviewer** (not the author) before
`/forge:design` proceeds (t5-2 self-validation lesson). Self-approval of the
anti-hallucination pass (Article III.4) and of the open-questions leanings is
prohibited. **DELIVERED: independent review design round 2 + final round 1
APPROVE recorded.**

##### NFR-B87-010 — Gates re-run POST-flip before any status promotion
The b8-3/b8-3b coupling guards and the full harness suite MUST be re-run AFTER
the `2.0.0.yaml` delivered-flip annotation is applied, not before (b8-coroot
lesson: gates re-run post-flip). **DELIVERED: full suite re-run post-flip.**

---

## Architecture Decision Records

| ADR | Decision | As-Implemented Resolution |
|-----|----------|--------------------------|
| **ADR-B87-001** | Install source + pins | Chart-referenced hybrid (helm install + Forge values overlay). Lean manifests-only **falsified** by live initJob/setupJob evidence (Q-001 Resolution). No raw K8s manifests vendored. Chart `zitadel 10.0.2` / appVersion `v4.14.0`, `ghcr.io/zitadel/zitadel:v4.14.0` — manifest-verified 2026-06-02. 4-file subtree: `values-forge.yaml.tmpl` + `README.md.tmpl` + `docker-compose.fragment.yml.tmpl` + `bootstrap.md.tmpl`. Both chart and image pins recorded in identity.yaml v1.1.0 `versions:` map. |
| **ADR-B87-002** | Datastore topology | Reuse shared `fsm-db` Postgres 17 (B.8.5 `pgvector/pgvector:0.8.2-pg17`) with a dedicated `zitadel` database + role for dev; Zitadel requires PG14+ (live-verified); dedicated-instance separation documented as T2/T3 prod posture. `postgresql.enabled: false` in values overlay (suppresses Bitnami subchart). DSN via `ZITADEL_DATABASE_POSTGRES_DSN` secretKeyRef. |
| **ADR-B87-003** | Bootstrap mechanism | Chart-native two-stage initJob + setupJob. `FirstInstance` env-var contract: `ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH`, `ZITADEL_FIRSTINSTANCE_PATPATH`, `ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH` — top-level under `FirstInstance:` (not org-nested, live-doc verified). Masterkey: exactly 32 bytes, injected via `masterkeySecretName` pre-created K8s Secret. OIDC client registration: Management API `POST /projects/{project_id}/apps/oidc` documented in `bootstrap.md.tmpl`. JWT rotation: Zitadel-managed, fully automatic — KeyConfig 6h/30h + WebKeys v2, no operator duty. |
| **ADR-B87-004** | Secrets posture + securityContext | Masterkey + admin secrets via K8s Secret refs generated at deploy time, never templated. `forge.dev/aegis-audit: "required"` + `forge.dev/standard: "identity.yaml@1.1.0"` annotations at pod level in values overlay (helm-template-verified). Minimal securityContext: `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `capabilities: drop: [ALL]`, no additional capabilities required. |
| **ADR-B87-005** | identity.yaml versioning | Additive 1.1.0 (first `versions:` map — standard becomes a pin source like `gateway.yaml`); no `breaking_change`; enforcement stays off (`ci_blocking: false`, `linter_rule: null`); `pin_review_cadence:` ISO 8601 added. `zitadel_chart: "10.0.2"`, `zitadel: "v4.14.0"`, `zitadel_login: "v4.14.0"` (all ghcr.io). `last_reviewed: 2026-06-02`, `expires_at: 2027-06-02`. |
| **ADR-B87-006** | Envoy OIDC wiring scope | Deferred actual SecurityPolicy/JWT filter + backend middleware to B.8.10/B.8.12 — this brick is the IdP infrastructure only. The delegation contract (`AT C4: Rel(envoy, zitadel, "OIDC")`) is documented in README; no SecurityPolicy, JWTAuthn filter, or backend auth middleware ships in B.8.7 scope. |

---

## BDD Acceptance Criteria

```gherkin
Feature: Zitadel IdP introduced additively as the 2.0.0 identity component via versioned subtree, standard bump, and schema annotation
  As a Forge B.8 migration architect
  I want the Zitadel identity subtree, datastore wiring, bootstrap mechanism, and standard bump
  delivered additively for the 2.0.0 candidate
  So that the flagship gains its first IdP infrastructure, the identity standard is properly versioned,
  and the frozen 1.0.0 stack is untouched

  Scenario: The 2.0.0 identity subtree lands additively without disturbing any frozen 1.0.0 asset
    <!-- Modified at design-phase by ADR-B87-001 (chart-referenced pivot), 2026-06-02 -->
    Given no 2.0.0/infra/zitadel/ subtree existing yet
    And the frozen 1.0.0 docker-compose.dev.yml.tmpl and template tree byte-identical to the B.8.2 freeze
    And identity.yaml at v1.0.0 with no versions: map
    And b8-3.test.sh (17 L1) and b8-3b.test.sh (12 L1) GREEN
    When the B.8.7 brick is implemented from these specs
    Then the 2.0.0/infra/zitadel/ subtree exists with values-forge.yaml.tmpl,
      README.md.tmpl, docker-compose.fragment.yml.tmpl, and bootstrap.md.tmpl
      (chart-referenced hybrid — no kustomization.yaml.tmpl, no raw manifests;
      ADR-B87-001)
    And values-forge.yaml.tmpl contains masterkeySecretName and
      forge.dev/aegis-audit: "required" sentinels
    And identity.yaml is version "1.1.0" with a versions: map containing at least one verified pin
    And identity.yaml default/alternatives/forbidden fields are byte-identical to v1.0.0
    And REVIEW.md has a new identity.yaml 1.1.0 ledger entry
    And 2.0.0.yaml zitadel component carries a # B.8.7 — delivered annotation
    And the implicit-auth → zitadel migration_delta strategy: additive-first is intact
    And the frozen 1.0.0 template tree is byte-unchanged (sha256 guard, B.8.2)
    And b8-3.test.sh (17/17) and b8-3b.test.sh (12/12) stay GREEN
    And b8-7.test.sh passes all 12 L1 checks within 2 s

  Scenario: Secrets posture holds — no secret value appears in any committed template
    Given the 2.0.0/infra/zitadel/ subtree present on disk
    And the README.md.tmpl contains a "NEVER PUT SECRETS HERE" warning
    And all workload templates carry forge.dev/aegis-audit: "required"
    When a maintainer runs the b8-7 harness secrets grep-guard (FR-B87-073)
    Then no file in 2.0.0/infra/zitadel/ contains a plaintext password, token, or masterkey
    And all credential references use ${ENV_VAR} or secretKeyRef: forms pointing to K8s Secrets
    And the harness PASSES the no-secret-values assertion

  Scenario: Scaffolding a 2.0.0 candidate remains refused until B.8.14
    Given the 2.0.0.yaml candidate with scaffoldable: false (ADR-B8-3-003/005)
    And the new 2.0.0/infra/zitadel/ subtree present on disk
    When forge init is invoked
    Then the scaffolder still emits the flat 1.0.0 template tree with no identity component
    And no 2.0.0 Zitadel template is scaffolded
    And scaffoldable: false is still the effective setting
    And no scaffolder code change ships in this brick
```
