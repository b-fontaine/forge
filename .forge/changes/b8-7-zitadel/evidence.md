# Verify-then-pin Evidence — b8-7-zitadel

<!-- Audit: B.8.7 (b8-7-zitadel) — verify-then-pin evidence ledger -->

This file records the LIVE-verified facts consumed by the ADRs in `design.md`.
Verification was performed at `/forge:design` on **2026-06-02** by the main
thread (Atlas role), using the GitHub Releases API, raw GitHub content, Docker
image manifests (`docker manifest inspect`), and the Helm chart values.yaml from
the upstream `zitadel/zitadel-charts` repository. All claims are reproducible
via the URLs in the provenance table below.

Per the b8-coroot lesson: pins are always resolved LIVE on the registry at the
appropriate phase. The final re-verify step at `/forge:implement` is still
required (ADR-B87-001 final-re-verify clause). Pin `v4.14.0` (chart-tested, NOT
the latest `v4.15.0`) — rationale recorded in Finding 4.

---

## Provenance Table

| #    | Source URL | Access date | Agent | What it proves |
|------|------------|-------------|-------|----------------|
| P-01 | `https://api.github.com/repos/zitadel/zitadel/releases` | 2026-06-02 | main thread | Zitadel latest stable release = **v4.15.0** (2026-05-04); prior stable = **v4.14.0**. Series is active on the v4 line. |
| P-02 | `https://api.github.com/repos/zitadel/zitadel-charts/releases` | 2026-06-02 | main thread | Helm chart latest = **zitadel-10.0.2** (2026-05-25); prior: 10.0.1/10.0.0 (2026-05-20); 9.34.1 (2026-05-04). |
| P-03 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/Chart.yaml` | 2026-06-02 | main thread | Chart.yaml: `name: zitadel`, `version: 10.0.2`, **`appVersion: v4.14.0`**, `kubeVersion: '>= 1.30.0-0'`, `type: application`. The chart's tested appVersion is **v4.14.0**, NOT v4.15.0. |
| P-04 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 26–27 | 2026-06-02 | main thread | **"ZITADEL requires PostgreSQL 14+ as its backing database"** — B.8.5 `pgvector/pgvector:0.8.2-pg17` (Postgres 17) satisfies the ≥14 requirement. |
| P-05 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 35–46 | 2026-06-02 | main thread | **DSN mode**: `ZITADEL_DATABASE_POSTGRES_DSN` env via `valueFrom.secretKeyRef` is the recommended connection path; when DSN is set, discrete fields are ignored. |
| P-06 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 159–169 | 2026-06-02 | main thread | **Masterkey constraint**: "Must be exactly 32 bytes", printable ASCII recommended; generation: `tr -dc A-Za-z0-9 </dev/urandom \| head -c 32`; `masterkeySecretName` = existing K8s Secret with key "masterkey" — "Use this for production deployments". |
| P-07 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 363–366 | 2026-06-02 | main thread | **Login UI split**: `login.enabled: true` default — separate Login UI deployment using `ghcr.io/zitadel/zitadel-login` (line 421). "When disabled, ZITADEL uses its built-in login interface." |
| P-08 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 729–732 | 2026-06-02 | main thread | Main Zitadel image: **`ghcr.io/zitadel/zitadel`** (GitHub Container Registry; NOT docker.io — the b8-coroot lesson: registries differ from training-data assumptions). |
| P-09 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 1065–1071 | 2026-06-02 | main thread | **initJob** (pre-install/pre-upgrade Helm hook, weight 1): "creates the database schema, user, and grants necessary permissions". |
| P-10 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` lines 1154–1162 | 2026-06-02 | main thread | **setupJob** (Helm hook weight 2, after initJob, before Deployment): "runs `zitadel setup` … creates the first organization, admin user, machine users, and generates authentication credentials stored as Kubernetes Secrets". |
| P-11 | `https://raw.githubusercontent.com/zitadel/zitadel/main/cmd/setup/steps.yaml` lines 114–158 | 2026-06-02 | main thread | **FirstInstance contract**: `ZITADEL_FIRSTINSTANCE_INSTANCENAME`, `_TRUSTEDDOMAINS`, `_ORG_NAME`, `_ORG_HUMAN_USERNAME/_PASSWORD/_PASSWORDCHANGEREQUIRED`, `_ORG_MACHINE_MACHINE_USERNAME`, `_MACHINEKEYPATH`, `_PATPATH`, `_LOGINCLIENTPATPATH`; `Skip: false`. Machine section creates service account with IAM_OWNER role. |
| P-12 | `docker manifest inspect ghcr.io/zitadel/zitadel:v4.14.0` | 2026-06-02 | main thread | **Image manifest live**: `ghcr.io/zitadel/zitadel:v4.14.0` ✓ (exists, manifest resolves). |
| P-13 | `docker manifest inspect ghcr.io/zitadel/zitadel-login:v4.14.0` | 2026-06-02 | main thread | **Login image manifest live**: `ghcr.io/zitadel/zitadel-login:v4.14.0` ✓ (exists, separate image for the login-UI deployment). |
| P-14 | `docker manifest inspect ghcr.io/zitadel/zitadel:v4.15.0` | 2026-06-02 | main thread | `ghcr.io/zitadel/zitadel:v4.15.0` ✓ manifest exists, but chart 10.0.2 appVersion is v4.14.0 — v4.15.0 is NOT chart-tested (see Finding 4). |

---

## Finding 1 — PostgreSQL 14+ compatibility: B.8.5 pgvector/pgvector:0.8.2-pg17 SATISFIES (P-04, ADR-B87-002)

Source: `values.yaml` lines 26–27 (P-04), 2026-06-02.

> "ZITADEL requires **PostgreSQL 14+** as its backing database"

B.8.5 ships `pgvector/pgvector:0.8.2-pg17` — Postgres major version **17**.
17 ≥ 14. The compatibility requirement is **satisfied**. No dedicated Postgres
container for Zitadel is required in dev; the B.8.5 `fsm-db` instance is reused
with a dedicated `zitadel` database and role (ADR-B87-002).

The lean in Q-002 (shared `fsm-db`) is **confirmed**. No falsification.

---

## Finding 2 — DSN mode: recommended connection path (P-05, ADR-B87-002)

Source: `values.yaml` lines 35–46 (P-05), 2026-06-02.

The chart recommends the **DSN mode** (`ZITADEL_DATABASE_POSTGRES_DSN` env var,
sourced from a `secretKeyRef`). When DSN is set, the discrete Postgres fields
(`host`, `port`, `database`, `user`, `password`) are ignored. The Forge overlay
(`values-forge.yaml.tmpl`) MUST wire the DSN via a K8s Secret reference, NOT via
discrete plaintext fields (ADR-B87-004). This satisfies FR-B87-021 (no secret
values committed) and FR-B87-025 (K8s Secret references only).

---

## Finding 3 — Masterkey: exactly 32 bytes, K8s Secret ref for production (P-06, ADR-B87-003/004)

Source: `values.yaml` lines 159–169 (P-06), 2026-06-02.

Verbatim constraint: **"Must be exactly 32 bytes"**. Printable ASCII recommended.
Generation command (verbatim from values.yaml): `tr -dc A-Za-z0-9 </dev/urandom | head -c 32`.

Production deployment: `masterkeySecretName` → reference to a pre-created K8s
Secret with key `"masterkey"`. The masterkey is **never** in the values overlay
— only the Secret *name* is referenced. This constraint is quoted verbatim in the
README (FR-B87-023) and in the values overlay comment (FR-B87-022). No masterkey
length was fabricated upstream of this live check.

---

## Finding 4 — Chart-tested pair: chart 10.0.2 + appVersion v4.14.0 (P-02/P-03, ADR-B87-001)

Source: Chart.yaml (P-03), GitHub releases (P-01/P-02), 2026-06-02.

**Central design decision**: the chart `10.0.2` declares `appVersion: v4.14.0`.
The latest Zitadel app release is `v4.15.0` (P-01), but **v4.15.0 is NOT the
chart-tested pair** — `10.0.2` was released 2026-05-25 with `v4.14.0` as its
tested appVersion. Using `v4.15.0` would mean running an image version that no
published chart version has been tested against.

**Lean falsification (Q-001/Q-004)**: the proposal leaned toward manifests-only
delivery. This lean is **falsified** by the live evidence:
1. The chart (`10.0.2`) carries operator-grade machinery (initJob + setupJob
   Helm hooks, secret generation via setupJob, login-UI wiring) that would
   require significant re-implementation if vendoring raw manifests only.
2. The setupJob (P-10) creates the first organisation, admin user, machine user,
   and stores credentials as K8s Secrets — this IS the bootstrap mechanism
   (ADR-B87-003). No separate bootstrap Job needs to be authored.
3. The login-UI split (P-07: `login.enabled: true` default) adds a second image
   (`ghcr.io/zitadel/zitadel-login:v4.14.0`, P-13) — the chart wires this
   topology automatically; manifests-only would require duplicating that logic.

**Decision** (ADR-B87-001): chart-referenced hybrid (option b), mirroring
B.8.4 ADR-B84-003. Chart `10.0.2` / appVersion `v4.14.0` is the pinned pair.
`v4.15.0` is NOT used in this brick; the rationale is recorded here (not
chart-tested). Re-verify LIVE at `/forge:implement` per ADR-B87-001.

Mirrors the B.8.5 DBOS precedent of recording falsified leanings explicitly.

---

## Finding 5 — initJob + setupJob: operator-grade two-stage bootstrap (P-09/P-10, ADR-B87-003)

Source: `values.yaml` lines 1065–1071 (P-09) and lines 1154–1162 (P-10), 2026-06-02.

**Stage 1 — initJob** (Helm pre-install/pre-upgrade hook, weight 1):
- Creates the database schema, database user, and grants necessary permissions.
- This runs BEFORE the main Zitadel Deployment starts.
- Satisfies FR-B87-036 (DB/role init for shared `fsm-db`): the chart's initJob
  handles schema+user creation on the K8s side; the dev compose fragment handles
  it via init-SQL (see ADR-B87-002).

**Stage 2 — setupJob** (Helm hook weight 2, after initJob, before Deployment):
- Runs `zitadel setup`.
- Creates the first organisation, admin user, machine users.
- Generates authentication credentials stored as Kubernetes Secrets.
- This IS the bootstrap mechanism for the root tenant + machine user (ADR-B87-003).
  The `FirstInstance` env-var contract (P-11) drives this setupJob.

No separate bootstrap Job needs to be authored — the chart setupJob IS the
bootstrap. OIDC client app registration requires a post-bootstrap Admin API call
using the machine-user PAT generated by the setupJob (documented recipe in README,
not wired by this brick). JWT signing-key rotation is Zitadel-managed (internal,
automatic) — no operator rotation duty per Zitadel docs; rotation cadence is not
fabricated here, it is documented as Zitadel-managed per official docs.

---

## Finding 6 — FirstInstance env-var contract (P-11, ADR-B87-003)

Source: `cmd/setup/steps.yaml` lines 114–158 (P-11), 2026-06-02.

Verified env-var names from the live `steps.yaml` (these are authoritative; NOT
fabricated from training data — anti-hallucination pass):

```
ZITADEL_FIRSTINSTANCE_INSTANCENAME
ZITADEL_FIRSTINSTANCE_TRUSTEDDOMAINS
ZITADEL_FIRSTINSTANCE_ORG_NAME
ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME
ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD
ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORDCHANGEREQUIRED
ZITADEL_FIRSTINSTANCE_ORG_MACHINE_MACHINE_USERNAME
ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH
ZITADEL_FIRSTINSTANCE_PATPATH
ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH
```

**Correction (independent review 2026-06-02)**: `MachineKeyPath`, `PatPath`, and
`LoginClientPatPath` are top-level fields directly under `FirstInstance:` in
`steps.yaml` lines 119–122 — NOT nested under `Org.Machine`. Their env mirrors
are therefore `ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH`,
`ZITADEL_FIRSTINSTANCE_PATPATH`, and `ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH`.
`ZITADEL_FIRSTINSTANCE_ORG_MACHINE_MACHINE_USERNAME` remains correct (it IS
org-nested). These three fields receive the machine user's key/PAT paths
(written to K8s Secrets by the setupJob) but are not org-nested in the YAML
hierarchy.

`Skip: false` in `steps.yaml` means the FirstInstance step is active by default.
The machine user section creates a service account with IAM_OWNER role —
suitable for post-bootstrap Admin API calls (OIDC client registration).

---

## Finding 7 — Login-UI topology: split by default in K8s; dev posture uses built-in (P-07/P-13, ADR-B87-001/Q-004)

Source: `values.yaml` lines 363–366 (P-07), 2026-06-02.

**K8s default** (`login.enabled: true`): separate `ghcr.io/zitadel/zitadel-login`
Deployment — a distinct container. The `values-forge.yaml.tmpl` overlay KEEPS
this default (realistic K8s topology documented in README).

**Dev posture** (`login.enabled: false` equivalent in compose): the dev compose
fragment uses the Zitadel container directly with its built-in login interface
(single service entry — simpler dev stack). This is documented explicitly in the
README as a deliberate dev/K8s topology difference (not an error).

**Registry** (b8-coroot lesson — registry identity confirmed):
- Main image: `ghcr.io/zitadel/zitadel` (NOT docker.io)
- Login image: `ghcr.io/zitadel/zitadel-login` (NOT docker.io)
Both images on **GitHub Container Registry (ghcr.io)**. v-prefix convention:
`v4.14.0` (opposite of coroot which used no v-prefix — convention recorded).

---

## /forge:implement Final Re-Verify Note

Per ADR-B87-001 and the b8-coroot lesson, the implementer MUST re-verify the
following LIVE at `/forge:implement`:

1. `https://api.github.com/repos/zitadel/zitadel-charts/releases/latest` —
   confirm `10.0.2` / `v4.14.0` is still the chart-tested pair (or escalate
   with `[NEEDS CLARIFICATION]` if a newer chart with a different appVersion
   has published since 2026-06-02).
2. `docker manifest inspect ghcr.io/zitadel/zitadel:v4.14.0` — confirm image
   still resolves.
3. `docker manifest inspect ghcr.io/zitadel/zitadel-login:v4.14.0` — confirm
   login image still resolves.
4. Re-read `values.yaml` masterkey constraint lines 159–169 — confirm 32-byte
   constraint unchanged.
5. Re-read `cmd/setup/steps.yaml` FirstInstance block — confirm env-var names
   unchanged.

If any check fails or shows a changed chart-tested pair, the implementer updates
the pins in `identity.yaml versions:` and `values-forge.yaml.tmpl` and records
the updated provenance in this file (append-only, new entries numbered P-15+).

---

## /forge:implement LIVE Re-Verify (executed 2026-06-02T18:04Z — main thread, Atlas)

The Phase 0 (T001–T007) re-verification was executed LIVE by the main thread at
`/forge:implement` on **2026-06-02 at 18:04Z**, per ADR-B87-001 final-re-verify
clause + b8-coroot lesson. Provenance appended below (P-15..P-21). Result:
**every design-phase pin CONFIRMED unchanged** — no escalation, no pin update
required. Phase 1 proceeds with the design pins (chart 10.0.2 / appVersion
v4.14.0 / login v4.14.0 / registry ghcr.io).

| #    | Source URL / Command | Access | Agent | What it proves |
|------|----------------------|--------|-------|----------------|
| P-15 | `https://api.github.com/repos/zitadel/zitadel-charts/releases/latest` + raw `Chart.yaml` | 2026-06-02T18:04Z | main thread | **T001 re-verify**: Chart.yaml `version: 10.0.2` / `appVersion: v4.14.0` / `kubeVersion: '>= 1.30.0-0'`; GH latest release `zitadel-10.0.2` (2026-05-25). Chart-tested pair (chart 10.0.2 ↔ appVersion v4.14.0) **CONFIRMED current** — no newer chart published since design. Pin UNCHANGED. |
| P-16 | `docker manifest inspect ghcr.io/zitadel/zitadel:v4.14.0` | 2026-06-02T18:04Z | main thread | **T002 re-verify**: `ghcr.io/zitadel/zitadel:v4.14.0` OK (manifest resolves; ghcr.io NOT docker.io). Pin UNCHANGED (P-12 confirmed). |
| P-17 | `docker manifest inspect ghcr.io/zitadel/zitadel-login:v4.14.0` | 2026-06-02T18:04Z | main thread | **T003 re-verify**: `ghcr.io/zitadel/zitadel-login:v4.14.0` OK (login-UI image resolves; `login.enabled: true` topology chart-supported). Pin UNCHANGED (P-13 confirmed). |
| P-18 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` (FirstInstance chart wiring) | 2026-06-02T18:04Z | main thread | **T004 chart values path RESOLVED**: FirstInstance config lives under `zitadel.configmapConfig.FirstInstance` (values:62-65, `Skip: false`). **CRITICAL — `MachineKeyPath` + `PatPath` are CHART-MANAGED** (values:66-70 verbatim: "the following fields are managed automatically by the Helm chart. Setting these manually is not supported and will cause the deployment to fail."). The chart auto-generates the machine key into a K8s Secret named after the machine `Username` (e.g. `iam-admin`, values:79-82); if a `Pat` block is defined a PAT is generated instead; additional system API users go under `configmapConfig.SystemAPIUsers` (values:104-113). ⇒ values-forge.yaml.tmpl MUST NOT set `MachineKeyPath`/`PatPath`; bootstrap.md references the auto-generated Secret. |
| P-19 | `proto/zitadel/management.proto` lines 3632-3635 (raw.githubusercontent.com) | 2026-06-02T18:04Z | main thread | **T005 Admin-API OIDC endpoint RESOLVED**: Management API `rpc AddOIDCApp` → `POST /projects/{project_id}/apps/oidc`. bootstrap.md recipe uses this endpoint with machine-user credentials (PAT auth). NOT fabricated. |
| P-20 | `cmd/defaults.yaml` lines 952-958 + 1196-1205 (raw.githubusercontent.com) | 2026-06-02T18:04Z | main thread | **T006 JWT signing-key rotation RESOLVED**: `SystemDefaults.KeyConfig` — `PrivateKeyLifetime: 6h` / `PublicKeyLifetime: 30h` (env `ZITADEL_SYSTEMDEFAULTS_KEYCONFIG_*`) = automatic rotation lifetimes; `DefaultInstance.WebKeys` — OIDC token signing keys generated at instance creation, default `Type: rsa`, `RSABits: 2048`, `RSAHasher: sha256`, ECDSA P256 option; dedicated `proto/zitadel/webkey/v2/webkey_service.proto`. Posture: **Zitadel-managed automatic** (6h/30h) + WebKeys v2 API for explicit rotation. NOT fabricated. |
| P-21 | `https://raw.githubusercontent.com/zitadel/zitadel-charts/main/charts/zitadel/values.yaml` line 26 | 2026-06-02T18:04Z | main thread | **T007 PG compat re-verify**: values.yaml:26 "ZITADEL requires PostgreSQL 14+" — UNCHANGED. B.8.5 `pgvector/pgvector:0.8.2-pg17` (Postgres 17 ≥ 14) COMPATIBLE. (P-04 confirmed.) |

### Finding 8 — FirstInstance chart wiring: configmapConfig.FirstInstance; MachineKeyPath/PatPath are CHART-MANAGED (P-18, ADR-B87-003 carry-item resolved)

The Q-003 carried verify-then-pin item ("FirstInstance values path in chart") is
RESOLVED at implement: the chart wires FirstInstance under
`zitadel.configmapConfig.FirstInstance` (NOT a dedicated `firstInstance:` top-level
block, NOT `extraEnv`). The maintainer-set fields are `InstanceName`, the
`Org.*` tree (Name / Human.Username / Human.Password / Human.PasswordChangeRequired /
Machine.Machine.Username), and `SystemAPIUsers`. **`MachineKeyPath` and `PatPath`
are CHART-MANAGED and MUST NOT be set in values-forge.yaml.tmpl** — the chart docs
state setting them manually "is not supported and will cause the deployment to
fail." The machine key / PAT is auto-generated into a K8s Secret named after the
machine user's `Username`. The values overlay therefore expresses FirstInstance
through `configmapConfig.FirstInstance` (with a `Pat: {ExpirationDate: ...}` block
to trigger PAT generation for the machine user) and the bootstrap doc references
the auto-generated Secret by its Username-derived name. This refines design-phase
ADR-B87-003 (which left the chart wiring path as a verify-at-implement carry item)
and supersedes the steps.yaml env-var-mirror framing for the chart path: in the
chart, FirstInstance is YAML config under `configmapConfig`, not `ZITADEL_FIRSTINSTANCE_*`
env mirrors. (The `ZITADEL_FIRSTINSTANCE_*` env names from P-11 remain authoritative
for the underlying Zitadel binary contract and are documented in bootstrap.md, with
the CHART-MANAGED ones marked do-not-set.)

### Finding 9 — Admin-API OIDC endpoint + JWT rotation cadence (P-19/P-20, ADR-B87-003 carry-items resolved)

Q-003 carried items #3 (Admin API OIDC endpoint) and #4 (JWT rotation cadence URL)
are RESOLVED at implement:

- **OIDC client registration** (P-19): Management API `rpc AddOIDCApp` →
  `POST /projects/{project_id}/apps/oidc`. bootstrap.md.tmpl uses this exact path +
  method with machine-user PAT auth (`Authorization: Bearer <pat>`).
- **JWT signing-key rotation** (P-20): Zitadel-managed automatic rotation via
  `SystemDefaults.KeyConfig` (`PrivateKeyLifetime: 6h`, `PublicKeyLifetime: 30h`);
  WebKeys (default RSA 2048 / sha256) generated at instance creation; explicit
  rotation available through the WebKeys v2 API
  (`proto/zitadel/webkey/v2/webkey_service.proto`). No operator rotation duty by
  default. bootstrap.md.tmpl documents the 6h/30h cadence + the defaults.yaml
  provenance + the WebKeys v2 API pointer. NOT fabricated.
