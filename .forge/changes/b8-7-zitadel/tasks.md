<!-- Audit: B.8.7 (b8-7-zitadel) -->
# Tasks: b8-7-zitadel

TDD-ordered. Four-file identity subtree (ADR-B87-001: values-forge.yaml.tmpl +
README.md.tmpl + docker-compose.fragment.yml.tmpl + bootstrap.md.tmpl under
2.0.0/infra/zitadel/). Chart/image pins are verify-then-pin LIVE at Phase 0
(ADR-B87-001 final-re-verify clause; b8-coroot lesson). The 2.0.0.yaml
annotation + identity.yaml v1.1.0 bump keep b8-3 17/17 + b8-3b 12/12 green
(NFR-B87-003). 1.0.0 frozen surfaces untouched (NFR-B87-002). No kustomization.yaml.tmpl
(chart-referenced hybrid — Spec Delta governs; FR-B87-002/071/072 MODIFIED by
ADR-B87-001). Subtree: exactly 4 files.

---

## Phase 0 — Verify-then-pin (LIVE re-execution, Article III.4 + b8-coroot lesson)

Every task in this phase queries a live external registry or authoritative source.
Each result MUST be appended to `evidence.md` with: URL, HTTP response timestamp,
value recorded, and a one-line summary of what it proves. If any pin differs from
the design ADR (chart 10.0.2 / appVersion v4.14.0 / login v4.14.0 / registry ghcr.io),
record the updated pin, update identity.yaml versions: accordingly, and continue.
If the chart-tested pair is ambiguous or if the image is absent, emit
`[NEEDS CLARIFICATION: <detail>]` and stop — do NOT proceed to Phase 1 with
unverified pins.

- [x] **T001** Re-query the `zitadel/zitadel-charts` GitHub Releases API
  (`https://api.github.com/repos/zitadel/zitadel-charts/releases/latest`) to
  confirm chart `10.0.2` is still current (or record the new latest). Re-fetch
  the raw `Chart.yaml` for the confirmed version to verify the `appVersion` field.
  The chart-tested pair (chart version ↔ appVersion) MUST be recorded as evidence
  (P-01 / P-02 / P-03 re-verify). If a newer chart has published, confirm its
  `appVersion`, update pins in identity.yaml `versions:` map and in
  `values-forge.yaml.tmpl` (written in Phase 4), and record provenance (P-15+).
  [Story: FR-B87-041, NFR-B87-007, ADR-B87-001]

- [x] **T002** Run `docker manifest inspect ghcr.io/zitadel/zitadel:v4.14.0`
  (or updated appVersion from T001). Confirm the image is present on
  `ghcr.io` (NOT docker.io — b8-coroot lesson confirmed at design P-12). Record
  the manifest digest + access timestamp as evidence (P-12 re-verify). If the
  image is absent, emit `[NEEDS CLARIFICATION: ghcr.io/zitadel/zitadel:<tag>
  not found — chart-tested pair may have rotated]` and stop.
  [Story: FR-B87-035, NFR-B87-007, ADR-B87-001]

- [x] **T003** Run `docker manifest inspect ghcr.io/zitadel/zitadel-login:v4.14.0`
  (or updated tag from T001). Confirm the login-UI image is present on `ghcr.io`
  (P-13 re-verify; evidence that login.enabled: true topology is chart-supported).
  Record the manifest digest + access timestamp. Same stop-on-absence rule as T002.
  [Story: FR-B87-035, NFR-B87-007, ADR-B87-001]

- [x] **T004** Re-check the `ZITADEL_FIRSTINSTANCE_*` env-var contract and
  FirstInstance values path in the chart. Re-fetch
  `https://raw.githubusercontent.com/zitadel/zitadel/v4.14.0/cmd/setup/steps.yaml`
  lines 114–158 (P-11 re-verify). Confirm:
  (a) `ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH`, `ZITADEL_FIRSTINSTANCE_PATPATH`,
  `ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH` are still top-level under
  `FirstInstance:` (NOT nested under `Org.Machine`).
  (b) The chart `values.yaml` wiring path for FirstInstance env mirrors
  (e.g., `zitadel.configmapConfig`, `extraEnv`, or dedicated `firstInstance:`
  block) — exact key path must be confirmed before authoring values-forge.yaml.tmpl.
  Record evidence (P-11 refresh + new P-15+ entry for the chart values path).
  If the contract has changed, emit `[NEEDS CLARIFICATION: FirstInstance env-var
  nesting change detected — ADR-B87-003 re-verify required]` and stop.
  [Story: FR-B87-020, FR-B87-024, ADR-B87-003]

- [x] **T005** Verify the Zitadel Admin API endpoint for OIDC client registration
  from live official Zitadel docs (`https://zitadel.com/docs` or the versioned
  OpenAPI spec for v4.14.0). Capture: the exact API path, HTTP method, and
  required request body shape for creating an OIDC application under a project.
  This endpoint populates the `[VERIFY AT IMPLEMENT]` placeholder in
  `bootstrap.md.tmpl` (ADR-B87-003 carry item). Record as evidence (P-16).
  Do NOT fabricate an endpoint if the docs are unclear — emit
  `[NEEDS CLARIFICATION: Admin API OIDC endpoint not resolved from live docs]` and stop.
  [Story: FR-B87-020, FR-B87-024, ADR-B87-003, Article III.4]

- [x] **T006** Verify the Zitadel JWT signing-key rotation documentation URL from
  live official Zitadel docs. Capture: the URL to the key management page for
  v4.14.0, and confirm the default rotation posture (Zitadel-managed, automatic)
  plus any stated default cadence. This URL populates the JWT rotation pointer in
  `bootstrap.md.tmpl` (ADR-B87-003 carry item). Record as evidence (P-17).
  Do NOT fabricate a URL — emit `[NEEDS CLARIFICATION: JWT rotation cadence URL
  not found in live docs]` if absent.
  [Story: FR-B87-027, ADR-B87-003, Article III.4]

- [x] **T007** Re-check Postgres compatibility: re-read
  `https://raw.githubusercontent.com/zitadel/zitadel-charts/zitadel-10.0.2/charts/zitadel/values.yaml`
  lines 26–27 (P-04 re-verify). Confirm "PostgreSQL 14+" requirement is unchanged
  (B.8.5 `pgvector/pgvector:0.8.2-pg17` satisfies 14+). Record as evidence
  (P-04 refresh). If the requirement has changed (e.g., moved to PG15+), record
  the new minimum and confirm B.8.5 still satisfies it; update README.md.tmpl
  wording accordingly.
  [Story: FR-B87-033, ADR-B87-002]

---

## Phase 1 — Harness RED

Author `b8-7.test.sh` with ALL ~12 L1 assertions before any template, standard
edit, or schema annotation. Run it immediately after authoring to confirm the
expected RED baseline. T-011 (b8-3/b8-3b coupling guard) may pass immediately
(already green before any edit) — record which tests pass and which fail.

- [x] **T008** Author `.forge/scripts/tests/b8-7.test.sh` (~12 L1 hermetic tests,
  mirror b8-6.test.sh structure: `--level` flag, `source _helpers.sh`,
  `run_test`, `print_summary`). Include all twelve assertions per design.md
  Testing Strategy table (T-001..T-012):
  - T-001: `2.0.0/infra/zitadel/values-forge.yaml.tmpl` exists
  - T-002: `2.0.0/infra/zitadel/README.md.tmpl` exists
  - T-003: `2.0.0/infra/zitadel/docker-compose.fragment.yml.tmpl` exists
  - T-004: `2.0.0/infra/zitadel/bootstrap.md.tmpl` exists
  - T-005: `values-forge.yaml.tmpl` carries both Aegis annotation sentinels
    (`forge.dev/aegis-audit: "required"` + `forge.dev/standard: "identity.yaml@1.1.0"`)
  - T-006: no plaintext password/secret in any file under `2.0.0/infra/zitadel/`
    (grep-guard: `password: [^$#{]` pattern, excluding comment lines)
  - T-007: `README.md.tmpl` contains OIDC delegation section + explicit scope-out
    phrase (`NOT shipped in this brick` or `deferred to B.8.10`) + AGPL licensing note
  - T-008: `identity.yaml` `version:` field is `"1.1.0"` AND contains
    a `versions:` block with at least `zitadel_chart:` + `zitadel:` keys
  - T-009: `REVIEW.md` contains a row referencing `identity.yaml` and `1.1.0`
    (FR-J7-023 anchor pattern `\| identity\.yaml \| 1\.1\.0 \|`)
  - T-010: `2.0.0.yaml` `zitadel` component carries the delivered annotation
    comment AND `standard: identity.yaml` still resolves AND
    `implicit-auth → zitadel` migration_delta with `strategy: additive-first`
    still present (Python yaml.safe_load + grep for `B.8.7.*delivered` or
    `delivered.*B.8.7`, plus `additive-first`)
  - T-011: coupling guard — `b8-3.test.sh --level 1` (17/17) + `b8-3b.test.sh
    --level 1` (12/12) both exit 0 (exit-code only, no output parse, within
    ≤ 2 s L1 budget)
  - T-012: `CHANGELOG.md` contains `b8-7-zitadel` entry (grep whole file per
    changelog-test lesson — survives release graduation)
  L1 budget ≤ 2 s, zero network/Docker.
  [Story: FR-B87-070, FR-B87-071, FR-B87-072, FR-B87-073, FR-B87-074,
   FR-B87-075, FR-B87-076, FR-B87-077, FR-B87-078, FR-B87-079, NFR-B87-001]

- [x] **T009** Run `bash .forge/scripts/tests/b8-7.test.sh --level 1` → verify
  RED baseline. RESULT 2026-06-02: 3 PASS / 9 FAIL. PASS = T-006 (no subtree → no
  secrets), T-010 (zitadel comp already resolves + `delivered_by: B.8.7` satisfies
  the whole-file delivered grep pre-annotation), T-011 (b8-3/b8-3b coupling already
  GREEN). FAIL = T-001..T-005, T-007, T-008, T-009, T-012 (delivery assertions). Expected fail: T-001..T-005, T-007..T-010, T-012 (no subtree,
  no standard bump, no annotation, no CHANGELOG). Expected pass: T-006 (no
  subtree yet → no secrets either), T-011 (b8-3/b8-3b coupling already green
  before any edit). Record the exact pass/fail counts.
  [Story: FR-B87-070, Article I RED]

---

## Phase 2 — GREEN: identity.yaml v1.1.0 + REVIEW.md

Standard edit FIRST — the `standard: identity.yaml` ref resolves since T.4 and
is not renamed (no resolution-order trap). The identity.yaml bump drives the pin
values used in the template files (Phase 4). Use Phase 0 verified pins only.

- [x] **T010** Edit `.forge/standards/identity.yaml`: bump `version: "1.0.0"` →
  `"1.1.0"` (additive — no `breaking_change: true`; ADR-B87-005). Changes:
  (a) `version: "1.1.0"`;
  (b) `last_reviewed: 2026-06-02`;
  (c) `expires_at: 2027-06-02` (12-month cycle; `exception_constitutional: false`
      preserved — FR-J7-020 coupling satisfied);
  (d) add `versions:` map with Phase 0 verified pins:
      `zitadel_chart:`, `zitadel:`, `zitadel_login:` (all from T001/T002/T003 —
      ghcr.io registry, v-prefix, chart-tested pair; NOT fabricated);
  (e) add `pin_review_cadence:` ISO 8601 block:
      `zitadel_chart: "P30D"`, `zitadel: "P12M"`, `zitadel_login: "P12M"`;
  (f) add or update the header comment block recording v1.1.0 + B.8.7 + 2026-06-02.
  The fields `default: zitadel`, `alternatives`, `forbidden`, `compliance_tier_aware`,
  `enforcement`, `linter_rule`, and `rationale` MUST be preserved verbatim —
  byte-stable (FR-B87-043). No `breaking_change` field added (FR-B87-047).
  [Story: FR-B87-040, FR-B87-041, FR-B87-042, FR-B87-043, FR-B87-046,
   FR-B87-047, ADR-B87-005]

- [x] **T011** Append a B.8.7 `Updated` entry to `.forge/standards/REVIEW.md`
  (append-only ledger, Article XII). The row MUST contain
  `| identity.yaml | 1.1.0 |` (FR-J7-023 anchor). Mirror the B.8.4 gateway.yaml
  and B.8.6 transport.yaml REVIEW.md precedents. Include: Reviewer @bfontaine,
  date 2026-06-02, decision KEEP-WITH-CHANGES, next review 2027-06-02, notes
  summarising the additive `versions:` map (chart 10.0.2 / app v4.14.0 /
  login v4.14.0 — all ghcr.io; chart-tested pair per evidence.md) +
  `pin_review_cadence:` addition; `default`/`alternatives`/`forbidden` byte-unchanged;
  no breaking change; machine enforcement stays off.
  [Story: FR-B87-044, FR-B87-045, ADR-B87-005]

- [x] **T012** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS] …identity.yaml` line. RESULT
  2026-06-02: STD_EXIT=0, `[STD-PASS] .forge/standards/identity.yaml` present;
  all 7 standards PASS. b8-7 harness now 5/12 PASS (T-008 + T-009 GREEN).
  (FR-B87-045; J.7 FR-J7-020 dated-expiry + FR-J7-023 REVIEW.md row checks run
  in dir context). Re-run `b8-7.test.sh --level 1` → T-008 and T-009 must now
  be GREEN. Record the new pass count.
  [Story: FR-B87-045, ADR-B87-005]

---

## Phase 3 — GREEN: 2.0.0.yaml delivered-flip annotation

- [x] **T013** Edit `.forge/schemas/full-stack-monorepo/2.0.0.yaml`: add inline
  comment `# default: zitadel — B.8.7 delivered` on the `standard: identity.yaml`
  line of the `zitadel` component, mirroring the B.8.6 connect-rpc annotation
  style (design.md §2.0.0.yaml annotation section; FR-B87-053). Shape:
  ```yaml
    - name: zitadel
      role: identity
      replaces: implicit-auth
      delivered_by: B.8.7
      standard: identity.yaml  # default: zitadel — B.8.7 delivered
  ```
  The `implicit-auth → zitadel` migration_delta with `strategy: additive-first`
  MUST remain intact (FR-B87-052). No forbidden inline-pin keys
  `{version, pin, image}` introduced (FR-B87-051; b8-3 T-012). No `^\d+\.\d+`
  scalar value added (b8-3 T-015). A YAML comment is transparent to
  `yaml.safe_load` — dict is byte-identical before and after (b8-3/b8-3b GREEN
  proof, design.md §2.0.0.yaml annotation section).
  [Story: FR-B87-050, FR-B87-051, FR-B87-052, FR-B87-053, FR-B87-054,
   ADR-B87-001]

- [x] **T014** Run `bash .forge/scripts/tests/b8-3.test.sh --level 1` → must
  exit 0 (17/17). RESULT 2026-06-02: b8-3 17/17 GREEN, b8-3b 12/12 GREEN
  post-annotation (comment transparent to yaml.safe_load). b8-7 T-010 GREEN. Run `bash .forge/scripts/tests/b8-3b.test.sh --level 1` →
  must exit 0 (12/12). Any failure is a B.8.7 constitutional violation
  (NFR-B87-003). Re-run `b8-7.test.sh --level 1` → T-010 must now be GREEN.
  Record pass counts.
  [Story: NFR-B87-003, FR-B87-054, FR-B87-078]

---

## Phase 4 — GREEN: 2.0.0 identity subtree (four files, ADR-B87-001)

Author all four template files using Phase 0 verified pins. No 1.0.0 frozen
file is touched (NFR-B87-002). No raw K8s manifests are vendored (chart-referenced
hybrid — ADR-B87-001). No `kustomization.yaml.tmpl` (FR-B87-002 superseded by
ADR-B87-001 per Spec Delta).

### G1 — values-forge.yaml.tmpl

- [x] **T015** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  infra/zitadel/values-forge.yaml.tmpl` (Forge Helm values overlay for
  `helm install zitadel/zitadel --version <chart-pin>`; ADR-B87-001). Content:
  (a) Top-of-file header block: audit comment `# <!-- Audit: B.8.7 (b8-7-zitadel) -->`,
      `# Standard: .forge/standards/identity.yaml` line (FR-B87-004),
      `# NEVER PUT SECRETS HERE` warning comment block (ADR-B87-004; FR-B87-022).
  (b) `masterkeySecretName: <project-name>-zitadel-masterkey` (pre-created K8s
      Secret; masterkey value NEVER in file — ADR-B87-004; FR-B87-025).
  (c) `postgresql: {enabled: false}` (suppresses bundled Bitnami subchart —
      ADR-B87-002; design.md §README.md.tmpl note re `--set postgresql.enabled=false`).
  (d) `login: {enabled: true}` (chart default, separate login-UI Deployment in K8s —
      ADR-B87-001 Q-004 resolution).
  (e) DSN secretKeyRef wiring for `ZITADEL_DATABASE_POSTGRES_DSN` via
      `valueFrom.secretKeyRef` pointing to a named K8s Secret (ADR-B87-004; FR-B87-025).
  (f) `firstInstance:` block (or `extraEnv:` / `zitadel.configmapConfig` per
      Phase 0 T004 confirmed chart values path) with the Phase 0 T004 verified
      env-var mirrors:
      `ZITADEL_FIRSTINSTANCE_INSTANCENAME`, `ZITADEL_FIRSTINSTANCE_TRUSTEDDOMAINS`,
      `ZITADEL_FIRSTINSTANCE_ORG_NAME`, `ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME`,
      `ZITADEL_FIRSTINSTANCE_ORG_MACHINE_MACHINE_USERNAME`,
      `ZITADEL_FIRSTINSTANCE_MACHINEKEYPATH`, `ZITADEL_FIRSTINSTANCE_PATPATH`,
      `ZITADEL_FIRSTINSTANCE_LOGINCLIENTPATPATH`
      (env-var names from live steps.yaml P-11; NOT fabricated; ADR-B87-003).
      Values expressed as template variables `<var-name>` or `${ENV_VAR}` — never literals.
  (g) Pod-level Aegis annotations under `podAnnotations:` or equivalent chart path:
      ```yaml
      forge.dev/aegis-audit: "required"
      forge.dev/standard: "identity.yaml@1.1.0"
      ```
      (FR-B87-006; ADR-B87-004; mirrors obi-daemonset.yaml.tmpl precedent).
  (h) Container-level securityContext override:
      ```yaml
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ALL]
      ```
      (FR-B87-007; ADR-B87-004; no `privileged: true`).
  Template variables use `<variable-name>` angle-bracket form (FR-B87-005).
  [Story: FR-B87-001, FR-B87-004, FR-B87-005, FR-B87-006, FR-B87-007,
   FR-B87-021, FR-B87-022, FR-B87-025, ADR-B87-001, ADR-B87-003, ADR-B87-004] [P]

### G2 — README.md.tmpl

- [x] **T016** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  infra/zitadel/README.md.tmpl` (ADR-B87-001; FR-B87-003). Content sections:
  (a) Audit header `<!-- Audit: B.8.7 (b8-7-zitadel) -->` (FR-B87-004).
  (b) Delivery model: chart-referenced hybrid (ADR-B87-001 decision; B.8.4-style);
      `standard: identity.yaml` policy-source reference.
  (c) `NEVER PUT SECRETS HERE` warning verbatim (FR-B87-022; ADR-B87-004):
      > **NEVER PUT SECRETS HERE.**
      > The masterkey and admin credentials are K8s Secrets generated at deploy time.
      > No secret value is committed to the repository. See the bootstrap section below.
  (d) Helm install block — MUST include `--set postgresql.enabled=false` (or
      equivalent `postgresql: {enabled: false}`) so adopters do not pull the
      bundled Bitnami subchart (ADR-B87-002; design.md §README.md.tmpl note;
      FR-B87-034):
      `helm install zitadel zitadel/zitadel --version <chart-pin> -f values-forge.yaml \`
      `  --set postgresql.enabled=false`
  (e) Masterkey generation + K8s Secret pre-creation commands: generation via
      `tr -dc A-Za-z0-9 </dev/urandom | head -c 32`; kubectl create secret with
      placeholder values (NOT real values; FR-B87-023; ADR-B87-003; masterkey
      "Must be exactly 32 bytes" per P-06).
  (f) Bootstrap stages overview (initJob → setupJob → Admin API recipe pointer
      to bootstrap.md.tmpl; FR-B87-020; ADR-B87-003).
  (g) DB topology section: shared fsm-db dev posture (dedicated `zitadel` database
      + `zitadel_user` role on the B.8.5 `fsm-db` Postgres 17 instance;
      ADR-B87-002; FR-B87-034) + T2/T3 prod recommendation (dedicated Postgres
      instance with network isolation).
  (h) Postgres compatibility note: PG 14+ requirement (P-04); B.8.5 `pgvector/pgvector:0.8.2-pg17`
      satisfies this (FR-B87-033; ADR-B87-002).
  (i) Dev vs K8s login topology difference note: K8s uses `login.enabled: true`
      (separate zitadel-login container); dev compose uses built-in login (single
      service — ADR-B87-001 Q-004; FR-B87-003).
  (j) T1/T2/T3 compliance posture section (FR-B87-060):
      - T1 Zitadel Cloud SaaS (⚠️), T2 self-host EU (✅), T3 self-host EU+SecNumCloud (✅);
      citing `compliance-tiers.md:121` verbatim Zitadel row; reference ADR-007
      (ARCHITECTURE-TARGET.md).
  (k) J8-RULE-002 cross-reference: note the T3 refusal already enforced by
      `forge-init-fsm.sh`; this brick only makes the guarded component deployable
      (FR-B87-061).
  (l) AGPL licensing note (FR-B87-062):
      > **License note**: Zitadel is licensed under the GNU Affero General Public
      > License v3 (AGPL-3.0). Review your organisation's open-source policy and
      > any applicable DPA requirements before deploying Zitadel in a commercial
      > product. See [zitadel.com](https://zitadel.com) for commercial licensing options.
  (m) Envoy → Zitadel OIDC delegation section (FR-B87-063):
      `AT C4: Rel(envoy, zitadel, "OIDC")` + cross-reference to
      `2.0.0/infra/k8s/envoy-gateway/` (ADR-B87-006; FR-B87-063).
  (n) Explicit scope-out statement VERBATIM (FR-B87-064):
      "The Envoy SecurityPolicy, JWTAuthn filter, and backend JWT validation
      middleware are NOT shipped in this brick. They are deferred to B.8.10
      (Envoy OIDC wiring) and B.8.12 (E2E migration tests)."
  (o) "Scope out (this brick)" section listing: Envoy SecurityPolicy/JWT-filter
      wiring (→ B.8.10), backend Rust auth middleware (→ B.8.12), Flutter OIDC
      client (→ B.8.10/B.8.12), Keycloak/Authentik alternative templates
      (identity.yaml alternatives documentation-only), identity.yaml machine
      enforcement (→ later brick) (FR-B87-066).
  Template variables use `<variable-name>` angle-bracket form (FR-B87-005).
  [Story: FR-B87-003, FR-B87-004, FR-B87-005, FR-B87-022, FR-B87-023,
   FR-B87-033, FR-B87-034, FR-B87-060, FR-B87-061, FR-B87-062, FR-B87-063,
   FR-B87-064, FR-B87-065, FR-B87-066, ADR-B87-001, ADR-B87-002, ADR-B87-006] [P]

### G3 — docker-compose.fragment.yml.tmpl

- [x] **T017** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  infra/zitadel/docker-compose.fragment.yml.tmpl` (ADR-B87-001; FR-B87-031).
  Content:
  (a) Top-of-file audit comment `# <!-- Audit: B.8.7 (b8-7-zitadel) -->` +
      `# NEVER PUT SECRETS HERE` warning comment block (FR-B87-031; ADR-B87-004).
  (b) Single service `fsm-zitadel` using `ghcr.io/zitadel/zitadel:<app-pin>`
      (Phase 0 T001/T002 verified tag; NOT fabricated; built-in login — no
      separate login container in dev; ADR-B87-001 Q-004).
  (c) `depends_on: fsm-db` (the B.8.5 service; ADR-B87-002).
  (d) DSN via `${ZITADEL_DB_DSN}` environment variable (env-file sourced, never
      hardcoded; ADR-B87-004; FR-B87-032).
  (e) Masterkey via `${ZITADEL_MASTERKEY}` environment variable (env-file sourced,
      NEVER committed; ADR-B87-004; FR-B87-032).
  (f) Port binding `127.0.0.1:8080:8080` (loopback only — FR-B87-008;
      NFR-B87-002 Aegis dev posture; NO `0.0.0.0` binding).
  (g) Self-validating structure: redeclare `networks:` and `volumes:` sections
      (B.8.5 postgres fragment pattern — enables `docker compose -f fragment.yml
      config` to validate standalone; FR-B87-031).
  (h) No plaintext production credentials — all credential references via
      `${ENV_VAR}` form (FR-B87-032; NFR-B87-004).
  Template variables use `<variable-name>` angle-bracket form (FR-B87-005).
  [Story: FR-B87-001, FR-B87-004, FR-B87-005, FR-B87-008, FR-B87-031,
   FR-B87-032, FR-B87-037, ADR-B87-001, ADR-B87-002, ADR-B87-004]

### G4 — bootstrap.md.tmpl

- [x] **T018** Author `.forge/templates/archetypes/full-stack-monorepo/2.0.0/
  infra/zitadel/bootstrap.md.tmpl` (ADR-B87-003; FR-B87-020). Content:
  (a) Audit header `<!-- Audit: B.8.7 (b8-7-zitadel, FR-B87-020/024/027) -->`.
  (b) Bootstrap stage summary: Stage 1 (initJob, Helm hook weight 1 — DB schema
      + user + grants on fsm-db), Stage 2 (setupJob, Helm hook weight 2 —
      `zitadel setup` with FirstInstance env → org + human admin + machine user
      (IAM_OWNER) + PAT written to K8s Secret; FR-B87-020; ADR-B87-003).
  (c) PAT retrieval recipe: `kubectl get secret <project-name>-zitadel-pat -o jsonpath=...`
      (or equivalent, per Phase 0 T004 verified secret name pattern — NOT fabricated;
      placeholder `<project-name>`; FR-B87-025).
  (d) Admin API OIDC client registration recipe using machine-user PAT:
      exact endpoint + HTTP method + request body from Phase 0 T005 live evidence
      (NOT fabricated; FR-B87-020; FR-B87-024; ADR-B87-003). Template variable
      for the Zitadel instance URL: `<zitadel-instance-url>`.
  (e) JWT signing-key rotation posture (FR-B87-027; ADR-B87-003):
      - State: Zitadel manages JWT signing keys internally (automatic rotation).
      - Default cadence: from Phase 0 T006 live evidence (NOT fabricated here).
      - Pointer URL: Phase 0 T006 verified official Zitadel key management docs URL.
  (f) Compliance note: OIDC client MUST use loopback/internal redirect URI in dev;
      production redirect URIs require adopter configuration.
  (g) All credential values in the recipe use placeholder form — no real secrets
      committed (FR-B87-021; NFR-B87-004).
  [Story: FR-B87-020, FR-B87-021, FR-B87-023, FR-B87-024, FR-B87-025,
   FR-B87-027, ADR-B87-003, ADR-B87-004]

### Helm template validation (implementation-phase, NOT an L1 harness gate)

- [x] **T019** Run `helm template zitadel zitadel/zitadel --version <chart-pin>
  -f .forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/values-forge.yaml.tmpl`
  (with placeholder values substituted) locally to verify the overlay renders
  correctly. This is a local validation step, not an L1 harness assertion (design.md
  §L2 opt-in note — harness is hermetic grep/stat only). Record the result (PASS
  or `[NEEDS CLARIFICATION: <helm error>]`). If `helm template` fails due to
  unknown key or syntax error, fix values-forge.yaml.tmpl before proceeding.
  RESULT 2026-06-02: helm 3 present (/opt/homebrew/bin/helm). `helm repo add
  zitadel https://charts.zitadel.com` + `helm template zitadel zitadel/zitadel
  --version 10.0.2 -f <overlay-with-placeholders> --set postgresql.enabled=false`
  → **HELM_RC=0** (14 manifest kinds rendered). Verified the overlay keys are
  EFFECTIVE in the rendered manifests: Aegis annotations render on the ZITADEL
  pod (`forge.dev/aegis-audit: required` + `forge.dev/standard: identity.yaml@1.1.0`),
  DSN `secretKeyRef` (`<project-name>-zitadel-db`) wired, `masterkeySecretName`
  wired, `allowPrivilegeEscalation: false` + `drop: [ALL]` applied across all 8
  containers, login-UI Deployment present. NOTE: corrected key placement during
  T019 after the first render — `env:`/`podAnnotations:`/`securityContext:` are
  TOP-LEVEL `.Values.*` keys in chart 10.0.2 (NOT nested under `zitadel:`);
  `FirstInstance.Org.Machine.Machine.Username` + sibling `Pat:` is the verified
  schema (`helm show values 10.0.2`). PASS.
  [Story: FR-B87-001, ADR-B87-001, NFR-B87-007]

---

## Phase 5 — GREEN: CHANGELOG + forge-ci.yml registration

- [x] **T020** Append a `## [Unreleased]` entry to `CHANGELOG.md` summarising
  the B.8.7 deliverables: 2.0.0/infra/zitadel/ identity subtree (4 files:
  values-forge.yaml.tmpl + README.md.tmpl + docker-compose.fragment.yml.tmpl +
  bootstrap.md.tmpl), identity.yaml v1.1.0 (first `versions:` map — Zitadel
  chart 10.0.2 / app v4.14.0 / login v4.14.0, all ghcr.io), 2.0.0.yaml zitadel
  delivered annotation, harness b8-7.test.sh. Entry MUST contain the string
  `b8-7-zitadel` (harness T-012 anchor — changelog-test lesson: grep whole file).
  Mirrors B.8.4 / B.8.5 / B.8.6 CHANGELOG precedent.
  [Story: FR-B87-079]

- [x] **T021** Append `"b8-7.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `b8-6.test.sh --level 1` line (FR-B87-070). Verify the CI file stays within
  the NFR-CI-002 ≤ 300-line budget.
  [Story: FR-B87-070, NFR-CI-002]

---

## Phase 6 — Full harness GREEN

- [x] **T022** Run `bash .forge/scripts/tests/b8-7.test.sh --level 1` → must
  exit 0 with all 12/12 GREEN. Record the full output. Any failure is a
  constitutional violation (Article V). Confirm T-011 coupling guard shows
  b8-3 (17/17) + b8-3b (12/12) both exiting 0.
  [Story: FR-B87-070..079, NFR-B87-001, NFR-B87-003]

---

## Phase 7 — Gates and sibling safety (NFR-B87-005 full-suite-before-push lesson)

Run all gates. A partial sweep is not sufficient — sibling scans can break
silently (b8-4/b8-5/b8-6 lessons; `full_harness_suite_before_push` project memory;
`shared-standard sibling-harness coupling` memory). Repo-wide scans MUST skip
`2.0.0/` subtrees (N.N.N/ convention from B.8.4/B.8.5; established in
scaffolding.md). Sibling version-pin scan: grep all harnesses for any that
hard-pin `identity.yaml` — those must still pass (identity.yaml was just bumped
to v1.1.0).

- [x] **T023** Run `bash bin/validate-standards-yaml.sh .forge/standards/` in
  DIRECTORY mode → must exit 0 with `[STD-PASS] …identity.yaml` line (among
  others). Confirm `| identity.yaml | 1.1.0 |` REVIEW.md anchor satisfies
  FR-J7-023 (J.7 drift check runs in dir context).
  [Story: FR-B87-045, NFR-B87-005]

- [x] **T024** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T025** Run `bash bin/constitution-linter.sh` → must exit 0. Record output.
  [Story: Article V]

- [x] **T026** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-7-zitadel/.forge.yaml` → must exit 0.
  [Story: Article V]

- [x] **T027** 1.0.0 byte-identity check: verify `b8-2.test.sh` frozen-sha256
  guard still passes (confirms 1.0.0 templates, schema.yaml, and 1.0.0.tar.gz
  are byte-unchanged):
  `bash .forge/scripts/tests/b8-2.test.sh --level 1` → exit 0.
  [Story: NFR-B87-002, FR-B87-010, FR-B87-037]

- [x] **T028** Run b8-3 and b8-3b one final time post all edits:
  `bash .forge/scripts/tests/b8-3.test.sh --level 1` → 17/17.
  `bash .forge/scripts/tests/b8-3b.test.sh --level 1` → 12/12.
  [Story: NFR-B87-003, FR-B87-054]

- [x] **T029** Sibling version-pin scan: grep all harnesses in
  `.forge/scripts/tests/` for any that reference `identity.yaml` (hard-pin
  version scan). If any harness greps for a specific identity.yaml version string,
  confirm it is either updated to `1.1.0` or does not break.
  Run any affected harnesses to confirm they still exit 0.
  [Story: NFR-B87-005, shared-standard sibling-harness coupling memory]

- [x] **T030** Run the FULL ~46-harness suite (all `*.test.sh` in
  `.forge/scripts/tests/`). Verify each harness exits 0 or is marked as
  expected-fail in forge-ci.yml. Pay special attention to any harness whose
  repo-wide scan might pick up the new `2.0.0/infra/zitadel/` subtree
  (delivery.test.sh, scaffolder.test.sh, b8-3.test.sh, b8-3b.test.sh,
  b8-4.test.sh, b8-5.test.sh, b8-6.test.sh) or the identity.yaml version bump.
  Any regression is a blocker.
  [Story: NFR-B87-005]

- [x] **T031** Neutralize any `[NEEDS CLARIFICATION:]` markers remaining in
  `specs.md` that were resolved by the ADRs (design phase) and by Phase 0 live
  evidence. Reword each `[NEEDS CLARIFICATION: ... — resolved at /forge:design
  via ...]` block to a resolved-by-ADR statement (e.g., "Resolved by ADR-B87-001:
  chart-referenced hybrid; see evidence.md P-01..P-14."). This MUST be done
  BEFORE the status flip to `implemented` (b8-coroot lesson: no open
  `[NEEDS CLARIFICATION:]` in finalized specs). Do NOT modify plan files
  (.omc/plans/*.md).
  [Story: Article III.4, NFR-B87-009]

---

## Phase 8 — Wrap-up (b8-coroot lesson + T5.2 lesson)

- [x] **T032** Flip `.forge/changes/b8-7-zitadel/.forge.yaml` status:
  `designed → planned` is done at plan time (this tasks.md); at implement-time
  flip `planned → implemented` AND add `timeline.implemented: <YYYY-MM-DD>`.
  **Re-run Phase 7 gates POST status flip** (b8-coroot lesson: gates must be
  re-run AFTER the flip, not trusted from pre-flip run). Specifically re-run:
  `b8-7.test.sh --level 1`, `b8-3.test.sh --level 1`, `b8-3b.test.sh --level 1`,
  `validate-standards-yaml.sh` dir-mode, `validate-change-yaml.sh`.
  [Story: Article V, NFR-B87-010, b8-coroot lesson]

- [x] **T033** Independent review pass (separate lane — author MUST NOT
  self-approve; NFR-B87-009; T5.2 self-validation lesson). The independent
  reviewer MUST re-execute (not trust the transcript):
  `b8-7.test.sh --level 1` (12/12), `b8-3.test.sh --level 1` (17/17),
  `b8-3b.test.sh --level 1` (12/12), `validate-standards-yaml.sh` dir-mode,
  `b8-2.test.sh --level 1` (frozen sha256 guard), and the secrets grep-guard
  (`grep -rn 'password: [^$#{]' .forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/`
  → zero matches expected). Record the reviewer's name and the run timestamp
  in the change record.
  [Story: NFR-B87-009, Article V.2, T5.2 lesson]

- [x] **T034** Archive prep: verify all tasks marked complete, run
  `/forge:archive b8-7-zitadel` to flip status `implemented → archived` after
  the independent review PASS. Confirm the B.8.10 / B.8.12 next-brick dependency
  chain is noted (ADR-B87-006 Envoy OIDC wiring deferred to B.8.10; ADR-B87-003
  bootstrapped PAT used by B.8.10/B.8.12 E2E tests).
  [Story: Article V, ADR-B87-006]

---

## FR-B87-* / NFR-B87-* Coverage Table

All 56 FRs + 10 NFRs covered. Delta-modified FRs (FR-B87-002/071/072 per Spec
Delta ADR-B87-001) map to their "Now:" text from specs.md.

| FR / NFR | Now: (if Delta-modified) | Task(s) |
|----------|--------------------------|---------|
| FR-B87-001 | — | T015, T016, T017, T022 |
| FR-B87-002 | MODIFIED: chart-referenced hybrid — no kustomization.yaml.tmpl; values-forge.yaml.tmpl is the vendor artifact | T015 (values-forge.yaml.tmpl delivered; kustomization not authored — ADR-B87-001) |
| FR-B87-003 | — | T016, T022 |
| FR-B87-004 | — | T015, T016, T017, T018 |
| FR-B87-005 | — | T015, T016, T017, T018 |
| FR-B87-006 | — | T015, T022 |
| FR-B87-007 | — | T015, T022 |
| FR-B87-008 | — | T017, T022 |
| FR-B87-009 | — | T014 (b8-3b coupling guard: scaffoldable:false invariant) |
| FR-B87-010 | — | T027 (b8-2 frozen sha256 guard) |
| FR-B87-020 | — | T004, T018, T022 |
| FR-B87-021 | — | T015, T017, T018, T022 |
| FR-B87-022 | — | T015, T016, T017, T022 |
| FR-B87-023 | — | T005, T016, T022 |
| FR-B87-024 | — | T004, T005, T018, T022 |
| FR-B87-025 | — | T015, T018, T022 |
| FR-B87-026 | N/A — no authored bootstrap Job; chart setupJob handles it (ADR-B87-003) | — |
| FR-B87-027 | — | T006, T018, T022 |
| FR-B87-030 | — | T001, T007 |
| FR-B87-031 | — | T017, T022 |
| FR-B87-032 | — | T015, T017, T022 |
| FR-B87-033 | — | T007, T016 |
| FR-B87-034 | — | T015, T016, T022 |
| FR-B87-035 | — | T001, T002, T003 |
| FR-B87-036 | Chart initJob handles K8s side; dev compose depends_on fsm-db; no separate init-SQL authored (ADR-B87-002) | T017 (compose depends_on fsm-db) |
| FR-B87-037 | — | T017, T027 (b8-2 guard — 1.0.0 postgres:16-alpine byte-unchanged) |
| FR-B87-040 | — | T010, T022 |
| FR-B87-041 | — | T001, T002, T003, T010, T022 |
| FR-B87-042 | — | T010, T022 |
| FR-B87-043 | — | T010, T022 |
| FR-B87-044 | — | T011, T022 |
| FR-B87-045 | — | T012, T023 |
| FR-B87-046 | — | T010, T022 |
| FR-B87-047 | — | T010 |
| FR-B87-050 | — | T013, T022 |
| FR-B87-051 | — | T013, T014 |
| FR-B87-052 | — | T013, T014, T022 |
| FR-B87-053 | — | T013 |
| FR-B87-054 | — | T014, T028 |
| FR-B87-060 | — | T016, T022 |
| FR-B87-061 | — | T016, T022 |
| FR-B87-062 | — | T016, T022 |
| FR-B87-063 | — | T016, T022 |
| FR-B87-064 | — | T016, T022 |
| FR-B87-065 | — | T016 |
| FR-B87-066 | — | T016, T022 |
| FR-B87-070 | — | T008, T009, T021 |
| FR-B87-071 | MODIFIED: harness MUST assert 4 files: values-forge.yaml.tmpl + README.md.tmpl + docker-compose.fragment.yml.tmpl + bootstrap.md.tmpl (no kustomization.yaml.tmpl) | T008 (T-001..T-004), T022 |
| FR-B87-072 | MODIFIED: harness MUST assert values-forge.yaml.tmpl contains masterkeySecretName AND forge.dev/aegis-audit sentinels (replaces kustomization-completeness check) | T008 (T-005), T022 |
| FR-B87-073 | — | T008 (T-006), T022, T033 |
| FR-B87-074 | — | T008 (T-005), T022 |
| FR-B87-075 | — | T008 (T-008), T010, T022 |
| FR-B87-076 | — | T008 (T-009), T011, T022 |
| FR-B87-077 | — | T008 (T-010), T013, T022 |
| FR-B87-078 | — | T008 (T-011), T014, T022 |
| FR-B87-079 | — | T008 (T-012), T020, T022 |
| NFR-B87-001 | — | T008, T009, T022 |
| NFR-B87-002 | — | T015, T016, T017, T018, T027 |
| NFR-B87-003 | — | T014, T022, T028 |
| NFR-B87-004 | — | T008 (T-006), T015, T017, T018, T033 |
| NFR-B87-005 | — | T029, T030 |
| NFR-B87-006 | — | T015, T016, T017, T018, T020, T021 |
| NFR-B87-007 | — | T001, T002, T003, T004, T005, T006, T007, T019 |
| NFR-B87-008 | — | T013, T014, T028 |
| NFR-B87-009 | — | T033 |
| NFR-B87-010 | — | T032 |
