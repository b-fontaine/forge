<!-- Audit: B.8.12 (b8-12-e2e-migration) -->
# Tasks: b8-12-e2e-migration

TDD-ordered. Additive convergence gate: committed 2.0.0 after-state golden
span inventory (superset of the 1.0.0 baseline 3 spans); migration E2E driver
(dry-run L1 + opt-in real Phase-2 overlay L2); 3-demo `.feature` byte-survival
(Spec-Delta-corrected paths) + demo-004 status:specified; Rust S2S Connect
client template `transport_connect_client.rs.tmpl` (connectrpc 0.6.x); Envoy
SecurityPolicy + backend JWT middleware templates (gateway.envoyproxy.io/v1alpha1
SecurityPolicy, CARRY-2/3/4 re-pinned at implement); methodology doc extension
to `docs/MIGRATIONS.md`; harness `b8-12.test.sh` (~23 L1 + 4 L2 opt-in) +
forge-ci.yml + CHANGELOG. 4 verify-at-implement carry items (CARRY-1..4) +
CARRY-5 live re-read block; ADR-B812-001..004 encoded; Spec Delta (ADR-B812-004
paths) governs demo-feature FR coverage. No standard bumped. No schema mutation.
No committed latency number (III.4 + ADR-B8-1-002). Independent review required
before `/forge:archive` (NFR-B812-009, t5-2 lesson).

---

## Phase 0 — Verify-then-pin LIVE + carry items (Article III.4 + b8-coroot lesson)

Re-read every artefact cited in the design LIVE before authoring any file.
Falsification → `[NEEDS CLARIFICATION: <detail>]` + STOP. Record each result in
`evidence.md` with file:line provenance (source-document-pinning.md). The four
CARRY items plus the base live re-read together form the stop-on-unresolved gate.

- [x] **T-001** Re-read the 1.0.0 baseline span inventory LIVE.
  Confirm `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`
  exists and records exactly **3** code-verified spans on demo-005-connect-greeting:
  (1) `otel_kind: client` with `verified_marker` containing `SpanKind.client`;
  (2) `name: http.request`, `otel_kind: server`, marker `otel.kind = "server"`;
  (3) `name: greeter.greet`, `otel_kind: internal`, marker `name = "greeter.greet"`.
  Confirm no `user.interaction` span appears (phantom absent — P-11).
  Confirm no `captured_at:` with a live timestamp beyond a date string.
  Record exact line numbers. If span count differs from 3 or the phantom is
  present, emit `[NEEDS CLARIFICATION: baseline span inventory changed — ADR-B812-001
  3-span assertion requires re-evaluation]` and STOP.
  [Story: FR-B812-001, FR-B812-002, FR-B812-003, ADR-B812-001, Article III.4]

- [x] **T-002** Re-read the fake-OTLP collector pattern LIVE (t5-otel-live-run).
  Confirm `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py`
  exists and imports only Python stdlib modules (no `protobuf`, `grpc`,
  `requests`, `opentelemetry` — mirrors `_test_olr_002_collector_stdlib_only`
  guard). Confirm `"<ts:redacted>"` placeholder is present in the sanitiser.
  Confirm the `run_smoke.sh` driver exists at the same path.
  Confirm the `diff -q` golden comparison pattern (`diff -q <cap> <golden>`) is
  used in `t5-otel-live-run.test.sh`. Record path + line refs as evidence
  (P-15..P-18 recheck). If the collector uses third-party imports, emit
  `[NEEDS CLARIFICATION: fake_otlp_collector.py has external deps — stdlib-only
  guarantee broken]` and STOP.
  [Story: FR-B812-005, FR-B812-063, NFR-B812-006, NFR-B812-007, ADR-B812-001]

- [x] **T-003** Re-read `bin/forge-migrate-flagship.sh` surface LIVE.
  Confirm: (a) flags `--target`, `--dry-run`, `--phase 0|1|2|all` are present;
  (b) exit-codes 0/2/5/7/8 documented (wrong-version → 7, P-12); (c) Phase 0
  preflight reads `archetype_version` from the manifest and exits 7 if not 1.0.0;
  (d) `--dry-run` prints the additive-delta plan and mutates nothing; (e) the
  ADDITIVE-ONLY constitutional invariant comment is present
  (`VIII.1/VIII.2 SHALL clauses binding until B.8.14`). Record exact line numbers.
  Also confirm `forge-ci.yml` still shows `b8-11.test.sh --level 1` as the
  current last b8-N line (insertion point for `b8-12.test.sh`). If the migration
  driver surface has changed materially, emit `[NEEDS CLARIFICATION: migration
  driver flags/exit-codes differ from ADR-B812-004 — tasks T-005..T-007 require
  re-evaluation]` and STOP.
  [Story: FR-B812-010, FR-B812-011, FR-B812-015, ADR-B812-004, Article III.4]

- [x] **T-004** Re-read demo-feature paths LIVE (Spec Delta, ADR-B812-004).
  Confirm the three demo `.feature` files exist at the Spec-Delta-corrected paths:
  - `examples/forge-fsm-example/.forge/changes/demo-001-*/features/*.feature`
  - `examples/forge-fsm-example/.forge/changes/demo-002-*/features/*.feature`
  - `examples/forge-fsm-example/.forge/changes/demo-003-*/features/*.feature`
  Confirm each file contains at least one `Scenario:` + `Given`/`When`/`Then`.
  Confirm `examples/forge-fsm-example/.forge/changes/demo-004-user-onboarding/`
  exists and `.forge.yaml` carries `status: specified` (no feature file).
  Confirm `examples/forge-fsm-example/shared/protos/` contains `.proto` files.
  Record exact glob expansions as evidence (P-19/P-20 recheck).
  If any demo-001..003 feature file is absent, emit
  `[NEEDS CLARIFICATION: Spec-Delta demo-feature path not found — FR-B812-020
  paths require re-verification]` and STOP.
  [Story: FR-B812-020, FR-B812-021, FR-B812-022, FR-B812-023, ADR-B812-004,
   Spec Delta §specs.md]

- [x] **T-005** CARRY-1 — Verify the exact connectrpc 0.6.1 client Cargo feature flag LIVE.
  Re-read the live `connectrpc` 0.6.1 crate `Cargo.toml` (crates.io or the
  pinned source referenced in P-01/P-23/P-24). Confirm whether the client
  surface (`HttpClient`, `ClientConfig`, `CallOptions`) requires an explicit
  `client` feature or is feature-implied by default. Then:
  - If `client` feature is required: the companion
    `Cargo.toml.tmpl` MUST carry `features = ["axum", "client"]`.
  - If feature-implied: document in the template header comment; `Cargo.toml.tmpl`
    stays `features = ["axum"]`.
  Record the exact `Cargo.toml` feature table entry as evidence (P-24 resolution).
  Do NOT fabricate the flag name. If the live crate is unreachable, emit
  `[NEEDS CLARIFICATION: connectrpc 0.6.1 crate Cargo.toml unavailable —
  CARRY-1 cannot be resolved; T-011/T-012/L2-04 blocked]` and STOP.
  [Story: FR-B812-031, ADR-B812-003, CARRY-1, Article III.4]

- [x] **T-006** CARRY-2 — Verify Zitadel OIDC discovery → jwks_uri path LIVE.
  Re-read the Zitadel OIDC discovery document (the `/.well-known/openid-configuration`
  endpoint for the chart-tested `v4.14.0` instance per identity.yaml v1.1.0).
  Extract the exact `jwks_uri` field value (conventionally `/oauth/v2/keys` but
  MUST NOT be hardcoded without live confirmation — ADR-B812-002 / ADR-B87-006).
  Record the full `jwks_uri` path as evidence (P-04 resolution). The SecurityPolicy
  `remoteJWKS` Backend and the backend middleware stub reference this verified path.
  If the discovery document is unreachable, the SecurityPolicy template carries
  `remoteJWKS.uri: "https://<zitadel-host>/.well-known/openid-configuration"` with
  a comment `# jwks_uri resolved from discovery at deploy-time — VERIFY-AT-DEPLOY`
  and no hardcoded path; record the fallback in evidence.md.
  [Story: FR-B812-043, FR-B812-044, ADR-B812-002, CARRY-2, Article III.4]

- [x] **T-007** CARRY-3 — Verify backend JWT tower Layer/Service shape LIVE.
  Re-read the axum/tower JWT validation ecosystem for Rust (connectrpc 0.6.x +
  axum — the same stack as `transport_connect.rs.tmpl`). Identify the JWT
  validation crate used (e.g., `jsonwebtoken`, `jwt-simple`, or the tower-http
  auth middleware pattern) and confirm the `Layer`/`Service` shape for an
  inbound request JWT validator. Record the crate name + version + key API shape
  as evidence (CARRY-3 resolution). If the shape cannot be cleanly pinned, the
  middleware template carries fully-documented stubs + the validation posture
  (issuer/audience checks, JWKS source = Zitadel discovery) with inline
  `// VERIFY-AT-DEPLOY` comments; record the fallback. Do NOT fabricate crate
  names or API shapes.
  [Story: FR-B812-042, ADR-B812-002, CARRY-3, Article III.4]

- [x] **T-008** CARRY-4 — Confirm Envoy SecurityPolicy v1.8.x JWT form LIVE.
  Re-read the Envoy Gateway v1.8.x SecurityPolicy CRD documentation (CARRY-4 from
  design.md). Confirm whether JWT is expressed via `spec.jwt.providers[]` folded
  into SecurityPolicy (i.e., no separate JWTAuthn resource in v1.8) or whether a
  distinct JWTAuthn resource exists. Per ADR-B812-002: `jwtauthn.yaml.tmpl` is a
  separate file ONLY if v1.8.x exposes a distinct JWTAuthn resource; otherwise
  the providers block IS the JWT wiring and only `securitypolicy.yaml.tmpl` is
  created. Record the exact CRD form + apiVersion/kind as evidence (P-03 + CARRY-4
  resolution). If the form cannot be confirmed live, fall back to middleware-only +
  a documented gateway stub per the ADR-B812-002 fallback; record explicitly in
  evidence.md + open-questions.md. Do NOT fabricate API strings.
  [Story: FR-B812-040, FR-B812-041, ADR-B812-002, CARRY-4, Article III.4]

---

## Phase 1 — Harness RED

Author `b8-12.test.sh` with all ~23 L1 assertions + 4 L2 stubs before any
template, golden, doc section, CHANGELOG entry, or CI line is created. Run to
confirm RED baseline. T-020 (frozen-file git diff) may partially pass pre-creation.
Record exact PASS/FAIL counts as the RED baseline.

- [x] **T-009** Author `.forge/scripts/tests/b8-12.test.sh`. The file MUST:
  (a) Open with the audit header (FR-B812-060):
      ```
      #!/usr/bin/env bash
      # Forge — B.8.12 E2E migration test harness (b8-12-e2e-migration)
      # <!-- Audit: B.8.12 (b8-12-e2e-migration) -->
      ```
  (b) `set -uo pipefail` as first executable statement.
  (c) `--level` flag parse loop (mirror t5-otel-live-run.test.sh:24-28);
      `HARNESS_DIR` + `FORGE_ROOT_REAL` resolution pattern.
  (d) Define path variables:
      `BASELINE_YAML="$FORGE_ROOT_REAL/.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml"`,
      `GOLDEN_YAML="$FORGE_ROOT_REAL/.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml"`,
      `COLLECTOR_PY="$FORGE_ROOT_REAL/examples/forge-fsm-example/test/live-run/fake_otlp_collector.py"`,
      `MIGRATE_SH="$FORGE_ROOT_REAL/bin/forge-migrate-flagship.sh"`,
      `C1_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example"`,
      `TRANSPORT_CLIENT="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl"`,
      `TRANSPORT_YML="$FORGE_ROOT_REAL/.forge/standards/transport.yaml"`,
      `ENVOY_OIDC_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway"`,
      `BACKEND_TPL_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend"`,
      `MIGRATIONS_DOC="$FORGE_ROOT_REAL/docs/MIGRATIONS.md"`,
      `CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"`,
      `FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"`.
  (e) `source "$HARNESS_DIR/_helpers.sh"`; `PASS=0; FAIL=0; FAIL_NAMES=()`.
  (f) Named test functions for all ~23 L1 tests (see T-010).
  (g) Named stubs for 4 L2 tests (see T-011), each gated on the appropriate
      env-var and emitting `SKIP: FORGE_B8_12_LIVE not set` (or
      `SKIP: FORGE_E2E_TOOLCHAINS not set`) when unset.
  (h) `main()` with `run_test` + `print_summary`;
      `case ",$LEVEL," in *,2,*) <L2 block>;; esac` structure.
  Make executable: `chmod +x .forge/scripts/tests/b8-12.test.sh`.
  [Story: FR-B812-060, FR-B812-061, Article I RED]

- [x] **T-010** Implement all ~23 L1 test functions (hermetic grep/stat/diff +
  one dry-run invocation; ≤ a few seconds wall-clock, NFR-B812-001):

  **T-001** `_test_b812_001_golden_present` — FR-B812-001:
  `[ -f "$GOLDEN_YAML" ]` → exit 0;
  `grep -q "archetype: full-stack-monorepo" "$GOLDEN_YAML"` → exit 0;
  `grep -q 'version: "2.0.0"' "$GOLDEN_YAML"` → exit 0. FAIL if any absent.

  **T-002** `_test_b812_002_three_span_superset` — FR-B812-002:
  `grep -q "SpanKind.client" "$GOLDEN_YAML"` → exit 0;
  `grep -q "http.request" "$GOLDEN_YAML"` → exit 0;
  `grep -q "greeter.greet" "$GOLDEN_YAML"` → exit 0. FAIL if any absent.

  **T-003** `_test_b812_003_phantom_absent` — FR-B812-003:
  `grep -q "user.interaction" "$BASELINE_YAML"` → exit 1 (absent);
  `grep -q "user.interaction" "$GOLDEN_YAML"` → exit 1 (absent).
  FAIL if either finds a match.

  **T-004** `_test_b812_004_goldens_sanitised` — FR-B812-004/NFR-006:
  For any companion `.golden.json` under
  `.forge/changes/b8-12-e2e-migration/captures/`:
  `grep -q '"<ts:redacted>"' <json-capture>` → exit 0;
  `! grep -qE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' <capture>` → exit 0.
  For the YAML golden, confirm no raw timestamp value (ISO8601 only or date string).
  FAIL if placeholder absent from JSON captures or any IPv4 found.

  **T-005** `_test_b812_005_migrate_dryrun_exit0` — FR-B812-010/ADR-B812-004:
  ```bash
  local tmpdir; tmpdir="$(mktemp -d)"
  trap "rm -rf '$tmpdir'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmpdir/c1"
  git -C "$tmpdir/c1" init -q
  git -C "$tmpdir/c1" add -A
  git -C "$tmpdir/c1" commit -q -m "init" --allow-empty
  bash "$MIGRATE_SH" --target "$tmpdir/c1" --dry-run >/dev/null 2>&1
  [ $? -eq 0 ]
  ```
  FAIL if dry-run exits non-zero.

  **T-006** `_test_b812_006_dryrun_additive_lines` — FR-B812-011:
  Capture the dry-run output to a tmpfile; assert
  `grep -q "Kong / Temporal / REST preserved" <out>` → exit 0;
  `git -C "$tmpdir/c1" status --porcelain` → empty (no mutation).
  FAIL if either assertion fails.

  **T-007** `_test_b812_007_exit7_wrong_version` — FR-B812-015:
  Create a tmpdir with `.forge/scaffold-manifest.yaml` carrying
  `archetype: full-stack-monorepo` + `archetype_version: 2.0.0`;
  `git init -q`; run `bash "$MIGRATE_SH" --target <tmp> --dry-run`;
  assert exit code is 7. FAIL otherwise.

  **T-008** `_test_b812_008_c1_gitclean_after` — FR-B812-012/NFR-003/010:
  `git -C "$FORGE_ROOT_REAL" diff --quiet examples/forge-fsm-example/` → exit 0;
  `grep -q "archetype_version: 1.0.0" "$C1_EXAMPLE/.forge/scaffold-manifest.yaml"` → exit 0.
  FAIL if c1 is dirty or manifest version is not 1.0.0.

  **T-009** `_test_b812_009_demo_features_gwt` — FR-B812-020/023 (Spec Delta):
  For each of demo-001, demo-002, demo-003: glob
  `"$C1_EXAMPLE/.forge/changes/demo-00${N}-*/features/*.feature"`;
  apply the awk Given/When/Then sentinel (mirror `_test_olr_010_feature_file_exists`):
  confirm `Feature:` + ≥1 `Scenario:` + `Given`/`When`/`Then` all present.
  FAIL if any of the 3 files is missing or awk check fails.

  **T-010** `_test_b812_010_demo004_specified` — FR-B812-022 (Spec Delta):
  `grep -q "status: specified" "$C1_EXAMPLE/.forge/changes/demo-004-user-onboarding/.forge.yaml"` → exit 0.
  FAIL if demo-004 is not status:specified.

  **T-011** `_test_b812_011_client_tmpl_present` — FR-B812-030:
  `[ -f "$TRANSPORT_CLIENT" ]` → exit 0. FAIL if absent.

  **T-012** `_test_b812_012_client_pin_and_posture` — FR-B812-031/032:
  `grep -qE "=0\.6" "$TRANSPORT_CLIENT" || grep -qE "connectrpc.*=0\.6" "$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl"` → exit 0;
  `grep -iqE "auth|tls|deadline|retry" "$TRANSPORT_CLIENT"` → exit 0.
  FAIL if pin sentinel absent or posture terms absent.

  **T-013** `_test_b812_013_transport_yaml_pin` — FR-B812-035:
  `grep -q "versions_2_0_0" "$TRANSPORT_YML"` → exit 0;
  `grep -qE "connectrpc.*=0\.6\.1" "$TRANSPORT_YML"` → exit 0.
  FAIL if either absent.

  **T-014** `_test_b812_014_envoy_oidc_tmpl_present` — FR-B812-040:
  `find "$ENVOY_OIDC_DIR" \( -name "*security*" -o -name "*jwt*" -o -name "*oidc*" \) -type f | grep -q .` → exit 0.
  FAIL if no matching file found.

  **T-015** `_test_b812_015_jwt_middleware_tmpl_present` — FR-B812-042:
  `find "$BACKEND_TPL_DIR" \( -name "*jwt*" -o -name "*auth*middleware*" \) -type f | grep -q .` → exit 0.
  FAIL if no matching file found.

  **T-016** `_test_b812_016_identity_crossref` — FR-B812-044:
  For the SecurityPolicy template (glob `"$ENVOY_OIDC_DIR"/*security*.tmpl`):
  `grep -qE "identity\.yaml|1\.1\.0" <template>` → exit 0. FAIL if absent.

  **T-017** `_test_b812_017_no_committed_p99` — FR-B812-006/051/NFR-004:
  ```bash
  ! grep -rqE 'p9[59][^a-z].*[0-9]+[[:space:]]*(ms|µs|s\b)' \
      "$FORGE_ROOT_REAL/.forge/changes/b8-12-e2e-migration/" \
      "$FORGE_ROOT_REAL/docs/MIGRATIONS.md" 2>/dev/null
  ```
  **SCOPE: grep targets the b8-12 change tree + MIGRATIONS.md only. Do NOT scan
  specs.md — it contains illustrative text (e.g., "p99:42ms") that is not a
  committed measurement. The anti-faked-latency guard is scoped to the new
  templates, goldens, and the methodology doc section.**
  FAIL if any committed numeric latency figure found in scope.

  **T-018** `_test_b812_018_methodology_doc` — FR-B812-050:
  `[ -f "$MIGRATIONS_DOC" ]` → exit 0;
  `grep -q "p99" "$MIGRATIONS_DOC"` → exit 0;
  `grep -q "B.8.13" "$MIGRATIONS_DOC"` → exit 0. FAIL if any absent.

  **T-019** `_test_b812_019_collector_stdlib_only` — FR-B812-063:
  Confirm the reused `fake_otlp_collector.py` imports no forbidden modules:
  for each of `protobuf google.protobuf grpc requests httpx yaml opentelemetry`:
  `grep -qE "^(import|from)[[:space:]]+${mod}" "$COLLECTOR_PY"` → exit 1.
  FAIL if any forbidden import found.

  **T-020** `_test_b812_020_frozen_files_unchanged` — FR-B812-033/045/NFR-003:
  Check that the frozen 1.0.0 flat-tree `transport_connect.rs.tmpl` and the 1.0.0
  infra Kong manifests are byte-unchanged:
  `git -C "$FORGE_ROOT_REAL" diff --quiet ".forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl"` → exit 0;
  `git -C "$FORGE_ROOT_REAL" diff --quiet ".forge/templates/archetypes/full-stack-monorepo/infra/"` → exit 0.
  FAIL if any diff lines found (frozen files modified).

  **T-021** `_test_b812_021_changelog_anchor` — FR-B812-067:
  `grep -q "b8-12-e2e-migration" "$CHANGELOG"` → exit 0 (whole-file grep,
  NOT section-scoped — changelog-test [Unreleased] coupling lesson). FAIL if absent.

  **T-022** `_test_b812_022_forgeci_registration` — FR-B812-066:
  `grep -q "b8-12.test.sh" "$FORGE_CI"` → exit 0. FAIL if absent.

  **T-023** `_test_b812_023_coupling_guards` — FR-B812-068:
  `bash "$HARNESS_DIR/b8-1.test.sh" --level 1 >/dev/null 2>&1` → exit 0;
  `bash "$HARNESS_DIR/b8-10.test.sh" --level 1 >/dev/null 2>&1` → exit 0.
  FAIL if either coupling guard exits non-zero.

  [Story: FR-B812-001..006, FR-B812-010..015, FR-B812-020..023,
   FR-B812-030..035, FR-B812-040..045, FR-B812-050..052,
   FR-B812-060..068, NFR-B812-001..010, Article I RED]

- [x] **T-011** Implement 4 L2 test stubs gated on env-vars (FR-B812-064/065):

  **L2-01** `_test_b812_l2_real_overlay` — FR-B812-013/064:
  Gate: `[ "${FORGE_B8_12_LIVE:-0}" = "1" ]` else emit
  `SKIP: FORGE_B8_12_LIVE not set`, return 0.
  When set: create a fresh tmpdir copy of c1 + `git init`;
  run `bash "$MIGRATE_SH" --target <tmp> --phase 2` (real overlay, not dry-run);
  assert exit 0; assert `infra/k8s/envoy-gateway/` directory exists in result;
  assert `grep -rq "kong" "$tmpdir/c1/docker-compose"*` → exit 0 (Kong preserved).

  **L2-02** `_test_b812_l2_viii_invariant` — FR-B812-014:
  Gate: `FORGE_B8_12_LIVE=1`.
  After the L2-01 real overlay: assert no Kong-related path or Temporal-related
  path was deleted (`diff -rq "$C1_EXAMPLE" "$tmpdir/c1" | grep "^Only in $C1_EXAMPLE"` → zero deletions for kong/temporal/rest-bridge paths). FAIL if any removal detected.

  **L2-03** `_test_b812_l2_methodology_leg` — FR-B812-052:
  Gate: `FORGE_B8_12_LIVE=1`.
  Assert methodology doc is readable (`[ -r "$MIGRATIONS_DOC" ]` → exit 0);
  assert the FORGE_B8_12_LIVE leg exercises the collector without error
  (run `python3 "$COLLECTOR_PY" --help 2>/dev/null || true`; the script exists
  and is Python-importable). Emit `SKIP: FORGE_B8_12_LIVE not set` when unset.

  **L2-04** `_test_b812_l2_cargo_check` — FR-B812-034/065:
  Gate: `[ "${FORGE_E2E_TOOLCHAINS:-0}" = "1" ]` else emit
  `SKIP: FORGE_E2E_TOOLCHAINS not set`, return 0.
  When set: render `$TRANSPORT_CLIENT` into a minimal tmpdir Rust project with a
  `Cargo.toml` declaring `connectrpc = "=0.6.1"` + required features; run
  `cargo check` → assert exit 0. FAIL if cargo-check exits non-zero.

  [Story: FR-B812-013, FR-B812-014, FR-B812-034, FR-B812-052,
   FR-B812-064, FR-B812-065]

- [x] **T-012** Run `bash .forge/scripts/tests/b8-12.test.sh --level 1` →
  confirm RED baseline. RED witness recorded 2026-06-04: 13 PASS / 10 FAIL.
  Failing (deliverables absent): T-001/002/003 (golden), T-011/012 (S2S client),
  T-014/015/016 (Envoy-OIDC + JWT middleware + identity xref), T-021 (CHANGELOG),
  T-022 (forge-ci). Pre-passing: T-004 (sanitised — no JSON captures yet),
  T-005/006/007/008 (dry-run driver + c1 git-clean), T-009/010 (demo survival),
  T-013 (transport.yaml pin shipped by B.8.6), T-017 (no committed p99),
  T-018 (methodology doc — MIGRATIONS.md already carries p99/B.8.13/B.8.12;
  Phase 5 adds the dedicated section), T-019 (collector stdlib-only),
  T-020 (frozen files), T-023 (b8-1 + b8-10 coupling GREEN). L2 skip-pass. Expected: T-001..T-018 mostly FAIL (golden absent,
  client template absent, Envoy-OIDC templates absent, methodology section absent,
  CHANGELOG anchor absent, forge-ci entry absent). Expected pre-creation PASS:
  T-003 (phantom absent from existing baseline), T-008 (c1 git-clean — passes since
  c1 is 1.0.0 and unmodified), T-010 (demo-004 status:specified — pre-existing),
  T-013 (transport.yaml pin — already shipped by B.8.6), T-019 (collector stdlib-only),
  T-020 (frozen files unchanged), T-023 (coupling guards if b8-1 + b8-10 GREEN).
  Record exact PASS/FAIL counts. If T-023 (coupling guards) is RED, resolve b8-1 and
  b8-10 coupling before proceeding. L2 tests → SKIP-pass when env-vars unset.
  [Story: FR-B812-062, Article I RED]

---

## Phase 2 — Golden gate + migration driver GREEN

Commit the 2.0.0 after-state golden span inventory and validate the
golden-superset diff logic + dry-run driver. Makes T-001..T-008 green.

- [x] **T-013** Create the captures directory and commit the 2.0.0 after-state
  golden span inventory (ADR-B812-001, FR-B812-001/002/003/004).
  Create `.forge/changes/b8-12-e2e-migration/captures/` directory.
  Author `full-stack-monorepo-2.0.0.span-inventory.yaml` using the same schema
  as the 1.0.0 baseline (`archetype`, `version`, `captured`, `demo`, `spans[]`
  with `name`, `otel_kind`, `layer`, `source`, `verified_marker`, `role` fields).
  The file MUST:
  (a) `archetype: full-stack-monorepo`, `version: "2.0.0"`;
  (b) Contain all 3 code-verified spans from the 1.0.0 baseline (spans are a SUPERSET):
      — span with `otel_kind: client`, `verified_marker` containing `SpanKind.client`;
      — span named `http.request`, `otel_kind: server`, marker `otel.kind = "server"`;
      — span named `greeter.greet`, `otel_kind: internal`, marker `name = "greeter.greet"`;
  (c) MAY contain additional 2.0.0 spans (additive);
  (d) MUST NOT contain any `user.interaction` span (phantom absent);
  (e) Carry no raw IPv4 addresses; `captured:` field uses a date string only
      (no live timestamp beyond YYYY-MM-DD). If companion `.golden.json` capture
      files are authored, they MUST use `"<ts:redacted>"` for all timestamp values.
  Run T-001, T-002, T-003, T-004 → must exit 0.
  [Story: FR-B812-001, FR-B812-002, FR-B812-003, FR-B812-004, ADR-B812-001]

- [x] **T-014** Validate the golden superset diff logic (FR-B812-005).
  Author the inline `diff -q`-style span subset check in the harness (T-010 T-001/T-002)
  and confirm it works against the committed golden: the three span names
  (`SpanKind.client`, `http.request`, `greeter.greet`) are present in the 2.0.0
  golden, the 1.0.0 baseline 3-span set is verified as a subset, and the assertion
  completes without Docker, cargo, or flutter.
  Run the harness T-001 + T-002 + T-003 → confirm GREEN.
  [Story: FR-B812-005, ADR-B812-001]

- [x] **T-015** Validate the migration dry-run driver and the additive-delta sentinel
  (FR-B812-010/011/012/015, ADR-B812-004).
  Run T-005 (dry-run exit 0 on 1.0.0 tmpdir copy) → GREEN.
  Run T-006 (dry-run output contains `Kong / Temporal / REST preserved`) → GREEN.
  Run T-007 (exit-7 on wrong-version 2.0.0 manifest) → GREEN.
  Run T-008 (committed c1 git-clean after, manifest still 1.0.0) → GREEN.
  If T-006 fails because the dry-run output text has changed (P-14 stale), re-read
  the migration driver live and update the grep sentinel to match the current text;
  record in evidence.md.
  [Story: FR-B812-010, FR-B812-011, FR-B812-012, FR-B812-015, ADR-B812-004]

- [x] **T-016** Validate the additive-overlay sentinel and demo-survival assertions.
  Run T-009 (demo-001..003 `.feature` Given/When/Then intact, Spec-Delta paths) → GREEN.
  Run T-010 (demo-004 status:specified) → GREEN.
  Confirm `.forge/changes/b8-12-e2e-migration/captures/` directory and golden
  are committed and `git diff` of examples/forge-fsm-example/ is empty.
  [Story: FR-B812-020, FR-B812-021, FR-B812-022, FR-B812-023, ADR-B812-004,
   Spec Delta §specs.md]

---

## Phase 3 — S2S Connect client GREEN

Land the Rust S2S Connect client template on the verified connectrpc 0.6.x
client API. Makes T-011, T-012, T-013, T-020 green.

- [x] **T-017** LIVE re-read connectrpc 0.6.x client API before authoring
  (b8-coroot lesson; CARRY-5 LIVE re-read). Re-read P-01 (connectrpc README +
  HttpClient/ClientConfig/CallOptions shape), P-23 (transport.yaml pins still
  `=0.6.1`), P-24 (CARRY-1 resolved — client feature flag confirmed or
  documented), P-25 (existing 2.0.0 `transport_connect.rs.tmpl` server adapter
  still byte-frozen). Record re-read timestamps in evidence.md. If any pin has
  changed (e.g., transport.yaml now shows `=0.6.2`), emit
  `[NEEDS CLARIFICATION: transport.yaml pin drift detected — ADR-B812-003
  requires re-evaluation]` and STOP.
  [Story: FR-B812-031, FR-B812-033, ADR-B812-003, CARRY-5, b8-coroot lesson]

- [x] **T-018** Create `transport_connect_client.rs.tmpl` at
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect_client.rs.tmpl`
  (ADR-B812-003, FR-B812-030/031/032/033).
  The template MUST:
  (a) Audit header: `// <!-- Audit: B.8.12 (b8-12-e2e-migration) — S2S Connect client template -->`;
  (b) Import the verified connectrpc 0.6.x client API symbols per P-01:
      `use connectrpc::client::{HttpClient, ClientConfig, CallOptions};`
      (exact symbols per CARRY-1/P-01 live read);
  (c) Implement client construction:
      `HttpClient::plaintext()` (cleartext in-cluster) OR `HttpClient::...with_tls()` (TLS);
      `ClientConfig::new(uri.parse()?).with_default_timeout(Duration::from_secs(30))
       .with_default_header("authorization", format!("Bearer {token}"))`;
      `<Svc>Client::new(http, config)`;
      `client.greet(req).await?` + per-call `client.greet_with_options(req, CallOptions::default().with_timeout(...))`;
  (d) The **four posture knobs** addressed inline (FR-B812-032):
      — **auth**: `with_default_header("authorization", "Bearer <token>")` comment cross-referencing the Zitadel machine-user token (ADR-B812-002);
      — **TLS**: `with_tls()` documented (cleartext for in-cluster, TLS for external);
      — **deadline**: `with_default_timeout` config default + per-call `CallOptions::default().with_timeout()` override;
      — **retry**: inline comment documenting retry posture (exact retry knob per CARRY-1 live read; if not pinnable → `// VERIFY-AT-DEPLOY: retry knob shape on connectrpc 0.6.1`);
  (e) The 1.0.0 flat-tree server adapter
      (`.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl`)
      is NOT modified.
  [Story: FR-B812-030, FR-B812-031, FR-B812-032, FR-B812-033, ADR-B812-003]

- [x] **T-019** Edit the companion
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/Cargo.toml.tmpl`
  to reflect the CARRY-1 resolution (FR-B812-031, ADR-B812-003):
  - If the `client` feature is required: add `"client"` to the `features = [...]` list
    → `features = ["axum", "client"]` (or the exact feature name confirmed in T-005).
  - If feature-implied by default: add a comment
    `# connectrpc client surface is feature-implied (confirmed CARRY-1, evidence.md P-24)`.
  Confirm `connectrpc = "=0.6.1"` pin is present (or the verified pin from T-005).
  [Story: FR-B812-031, ADR-B812-003, CARRY-1]

- [x] **T-020** Run T-011 (client template present), T-012 (pin sentinel + posture
  terms), T-013 (transport.yaml versions_2_0_0 block), T-020 (frozen 1.0.0 + 2.0.0
  server adapter byte-unchanged) → must all exit 0. FAIL on any regression.
  [Story: FR-B812-030, FR-B812-031, FR-B812-032, FR-B812-033, FR-B812-035]

---

## Phase 4 — Envoy-OIDC wiring GREEN

Land the SecurityPolicy template, the backend JWT middleware template, and the
kustomization update. Makes T-014, T-015, T-016, T-020 green.

- [x] **T-021** LIVE re-read before authoring Envoy-OIDC templates (b8-coroot lesson;
  CARRY-4/2/3 resolution must be recorded before the first template line).
  Re-read P-03 (Envoy Gateway v1.8.x SecurityPolicy CRD — `gateway.envoyproxy.io/v1alpha1`,
  `spec.jwt.providers[].remoteJWKS.backendRefs`→Backend shape per CARRY-4 resolution),
  P-04 (Zitadel discovery → jwks_uri per CARRY-2 resolution), P-28 (gateway.yaml
  v1.8.0 chart pin unchanged), P-29 (identity.yaml v1.1.0 pins: chart 10.0.2,
  appVersion v4.14.0). Record re-read timestamps. If the SecurityPolicy API has
  changed from `gateway.envoyproxy.io/v1alpha1`, emit
  `[NEEDS CLARIFICATION: Envoy Gateway SecurityPolicy apiVersion changed —
  ADR-B812-002 requires re-evaluation]` and STOP.
  [Story: FR-B812-040, FR-B812-041, FR-B812-043, FR-B812-044, ADR-B812-002, CARRY-4/2/3]

- [x] **T-022** Create the Envoy SecurityPolicy template at
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/securitypolicy.yaml.tmpl`
  (ADR-B812-002, FR-B812-040/041/043/044/045).
  The template MUST:
  (a) `apiVersion: gateway.envoyproxy.io/v1alpha1`, `kind: SecurityPolicy`
      (per CARRY-4 live read — if v1.8.x exposes a distinct JWTAuthn resource,
      also create `jwtauthn.yaml.tmpl` in the same directory);
  (b) `spec.targetRef`:
      `{group: gateway.networking.k8s.io, kind: HTTPRoute, name: <route>}`;
  (c) `spec.jwt.providers[]`:
      `name: <provider-name>`,
      `issuer: <zitadel-ExternalDomain>` (from `values-forge` overlay, cross-ref
      identity.yaml@1.1.0),
      `audiences: [<client-id>]`,
      `remoteJWKS.backendRefs: [{group: gateway.envoyproxy.io, kind: Backend,
       name: <jwks-backend>, port: 443}]`
      (or the verified form per CARRY-4; include the jwks_uri from CARRY-2);
  (d) Audit comment: `# <!-- Audit: B.8.12 (b8-12-e2e-migration) -->`;
  (e) Cross-reference comments: `# identity.yaml@1.1.0 (chart 10.0.2,
      appVersion v4.14.0, ghcr.io)` and `# gateway.yaml v1.8.0`;
  (f) CARRY-2 resolution: the `remoteJWKS` URI references the verified Zitadel
      jwks_uri (or the documented fallback if not pinnable).
  **FALLBACK (ADR-B812-002)**: if CARRY-4 or CARRY-2 cannot be cleanly resolved
  at this point, create the template with a fully-documented skeleton and all
  unresolved fields marked `# VERIFY-AT-DEPLOY: <reason>`. Record the fallback
  in evidence.md + open-questions.md. No fabricated API strings.
  The existing 1.0.0 `infra/k8s/` Kong manifests (flat-tree) are NOT modified
  (FR-B812-045).
  [Story: FR-B812-040, FR-B812-041, FR-B812-043, FR-B812-044, FR-B812-045,
   ADR-B812-002, CARRY-2/4]

- [x] **T-023** Create the backend JWT validation middleware template at
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/<resolved-path>/<jwt-middleware>.rs.tmpl`
  (exact path resolved per CARRY-3; ADR-B812-002, FR-B812-042).
  The template MUST:
  (a) Audit comment header;
  (b) Implement or stub a tower `Layer`/`Service` that validates the inbound
      `authorization` header JWT (per CARRY-3 live shape);
  (c) Validation posture documented inline: issuer check, audience check,
      JWKS source = Zitadel discovery (cross-ref ADR-B812-002 + identity.yaml@1.1.0);
  (d) Cross-reference the SecurityPolicy template (the Envoy side validates first;
      this is a defense-in-depth layer);
  (e) Any unpinnable shape is marked `// VERIFY-AT-DEPLOY: <crate/API>` — no fabrication.
  [Story: FR-B812-042, ADR-B812-002, CARRY-3]

- [x] **T-024** Edit the kustomization template to list the new Envoy-OIDC resource files
  (ADR-B812-002 carry, design Change Surface table).
  Edit `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/kustomization.yaml.tmpl`
  to add `securitypolicy.yaml` (and `jwtauthn.yaml` if created in T-022) to the
  `resources:` list. This is an EDIT to an existing 2.0.0 template file (additive
  list entry only — not a new template).
  [Story: FR-B812-040, ADR-B812-002]

- [x] **T-025** Run T-014 (Envoy-OIDC templates present), T-015 (JWT middleware present),
  T-016 (identity.yaml cross-ref), T-020 (1.0.0 Kong infra frozen) → must all
  exit 0. Confirm frozen 1.0.0 flat-tree infra is byte-unchanged.
  [Story: FR-B812-040, FR-B812-042, FR-B812-044, FR-B812-045]

---

## Phase 5 — Methodology doc GREEN

Extend `docs/MIGRATIONS.md` with the latency measurement methodology section.
Makes T-017, T-018 green.

- [x] **T-026** Append a "Latency measurement methodology (B.8.12 — when a real
  backend image exists)" section to `docs/MIGRATIONS.md` (ADR-B812-001, Q-005,
  FR-B812-050/051/052).
  The section MUST:
  (a) Anchor to B.8.12 in the heading or a comment;
  (b) Describe the measurement procedure for p50/p95/p99 once a real backend image
      exists, cross-referencing `docs/B8-BASELINE.md §6` (the re-measurement
      methodology procedure reference);
  (c) Reference the B.8.13 rollback thresholds: p99 >20% regression, traceparent
      errors >1% (relative percentages only — no frozen ms value);
  (d) Note that the `FORGE_B8_12_LIVE` opt-in leg exercises the methodology flow
      and skip-passes without toolchains;
  (e) Contain the string `p99` and `B.8.13` (testable — T-018);
  (f) Commit NO numeric p95/p99 latency figure (machine-verified by T-017
      anti-faked-latency guard scoped to MIGRATIONS.md).
  [Story: FR-B812-050, FR-B812-051, FR-B812-052, ADR-B812-001, III.4]

- [x] **T-027** Run T-017 (anti-faked-latency guard — scoped to b8-12 change tree +
  MIGRATIONS.md, NOT specs.md) → must exit 0. Run T-018 (methodology doc present,
  `p99` + `B.8.13` present) → must exit 0.
  Confirm no numeric latency figure is present in the new MIGRATIONS.md section.
  [Story: FR-B812-050, FR-B812-051, NFR-B812-004, III.4]

---

## Phase 6 — CHANGELOG + CI GREEN

Add CHANGELOG entry and register the harness. Makes T-021, T-022 green.

- [x] **T-028** Append an `[Unreleased]` entry to `CHANGELOG.md` (FR-B812-067).
  The entry MUST contain the string `b8-12-e2e-migration` (whole-file grep, NOT
  bare "B.8.12" — changelog-test [Unreleased] coupling lesson). Content:
  2.0.0 after-state golden span inventory committed (superset of 1.0.0 3-span
  baseline); migration E2E driver (dry-run L1 + L2 opt-in `FORGE_B8_12_LIVE`);
  Rust S2S Connect client template `transport_connect_client.rs.tmpl` (connectrpc
  =0.6.1); Envoy SecurityPolicy + JWT + backend middleware templates
  (gateway.envoyproxy.io/v1alpha1; identity.yaml@1.1.0); latency methodology doc
  in `docs/MIGRATIONS.md`; harness `b8-12.test.sh` (~23 L1 + 4 L2); forge-ci.yml
  registration; release target v0.4.0-rc.14.
  [Story: FR-B812-067]

- [x] **T-029** Append `"b8-12.test.sh --level 1"` as a one-line entry to the
  `harnesses=()` loop in `.github/workflows/forge-ci.yml` after the
  `"b8-11.test.sh --level 1"` line (FR-B812-066).
  [Story: FR-B812-066]

---

## Phase 7 — Harness GREEN + L2 opt-in

Run the full harness after all deliverables are in place.

- [x] **T-030** Run `bash .forge/scripts/tests/b8-12.test.sh --level 1` →
  must exit 0 with all ~23 L1 tests GREEN. DONE 2026-06-04: 23/23 L1 GREEN, exit 0.
  Confirm:
  - T-001 (2.0.0 golden present + schema) GREEN
  - T-002 (3-span superset: client + http.request + greeter.greet) GREEN
  - T-003 (phantom user.interaction absent) GREEN
  - T-004 (goldens sanitised: ts:redacted + no IPv4) GREEN
  - T-005 (migration dry-run exit 0 on 1.0.0 tmpdir copy) GREEN
  - T-006 (dry-run output: additive-delta lines + preservation invariant) GREEN
  - T-007 (exit-7 on wrong-version 2.0.0 tmpdir) GREEN
  - T-008 (committed c1 git-clean after; manifest still 1.0.0) GREEN
  - T-009 (demo-001..003 feature files Given/When/Then intact, Spec-Delta paths) GREEN
  - T-010 (demo-004 status:specified) GREEN
  - T-011 (transport_connect_client.rs.tmpl present) GREEN
  - T-012 (connectrpc =0.6 pin sentinel + auth/tls/deadline/retry posture terms) GREEN
  - T-013 (transport.yaml versions_2_0_0 + connectrpc pin) GREEN
  - T-014 (Envoy-OIDC template(s) present in 2.0.0 subtree) GREEN
  - T-015 (backend JWT middleware template present) GREEN
  - T-016 (identity.yaml@1.1.0 cross-ref in Envoy-OIDC template) GREEN
  - T-017 (no committed p99 number — scoped guard) GREEN
  - T-018 (methodology doc present + p99 + B.8.13) GREEN
  - T-019 (fake-OTLP collector stdlib-only guard) GREEN
  - T-020 (frozen 1.0.0 files byte-unchanged) GREEN
  - T-021 (CHANGELOG anchor b8-12-e2e-migration) GREEN
  - T-022 (forge-ci.yml b8-12.test.sh registered) GREEN
  - T-023 (coupling guards: b8-1 + b8-10 exit 0) GREEN
  L2 tests → SKIP-pass when env-vars unset. Record full output.
  Any FAIL is a constitutional violation (Article V). Resolve before proceeding.
  [Story: FR-B812-062, NFR-B812-001, Article V]

- [x] **T-031** L2 opt-in validation (if toolchains available). DONE 2026-06-04:
  cargo + docker + python3 all present on the impl host. `FORGE_B8_12_LIVE=1
  FORGE_E2E_TOOLCHAINS=1 b8-12.test.sh --level 2` → 27/27 GREEN. L2-01 (real
  Phase-2 overlay: envoy-gateway dir present + Kong preserved) GREEN; L2-02
  (VIII.1/VIII.2: no Kong/Temporal/REST removed) GREEN; L2-03 (methodology leg)
  GREEN; L2-04 (cargo-check on rendered S2S client) GREEN — and it CAUGHT a real
  API mismatch (ClientConfig::new takes Uri not &str, evidence.md P-42), fixed
  before GREEN. Committed c1 stayed git-clean throughout. Without env vars: 27/27
  skip-pass (honest).
  If `FORGE_B8_12_LIVE=1` can be set: run
  `FORGE_B8_12_LIVE=1 bash .forge/scripts/tests/b8-12.test.sh --level 2`.
  Assert L2-01 (real overlay: envoy-gateway dir present + Kong preserved) GREEN;
  L2-02 (VIII.1/VIII.2: no Kong/Temporal/REST path removed) GREEN;
  L2-03 (methodology leg exercised) GREEN.
  If `FORGE_E2E_TOOLCHAINS=1` also available: assert L2-04 (cargo-check on
  rendered S2S client) GREEN.
  If neither env-var can be set: record `SKIP: toolchains unavailable — L2
  skip-pass as designed`. Skip is NOT a FAIL.
  [Story: FR-B812-013, FR-B812-014, FR-B812-034, FR-B812-052,
   FR-B812-064, FR-B812-065]

---

## Phase 8 — Gates + sibling scan + wrap-up

Run all gates. A partial sweep is insufficient — sibling scans can break
silently (`full_harness_suite_before_push` + `shared-standard sibling-harness
coupling` project memory lessons). Repo-wide scans MUST skip `N.N.N/` versioned
subtrees.

- [x] **T-032** Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-12-e2e-migration/.forge.yaml` → must exit 0. Record output.
  [Story: Article V]

- [x] **T-033** Run `bash bin/verify.sh` → must exit 0 (PASS). Record output.
  [Story: Article V]

- [x] **T-034** Run `bash .forge/scripts/constitution-linter.sh` → must produce
  `OVERALL PASS`. Confirm the ADDITIVE-ONLY invariant is not violated (no Kong/
  Temporal removal), no new DBOS reference introduced, no committed p99 number.
  Record output.
  [Story: NFR-B812-008, Article V, VIII.1, VIII.2]

- [x] **T-035** Run `bash bin/validate-standards-yaml.sh .forge/standards/`
  → must exit 0. Confirm transport.yaml, gateway.yaml, identity.yaml all pass
  schema validation (none is bumped by B.8.12 — Finding 4). Record output.
  [Story: NFR-B812-002, Article V]

- [x] **T-036** Coupling final: re-run `b8-1.test.sh --level 1` and
  `b8-10.test.sh --level 1` standalone → both exit 0. These are the named
  dependencies (FR-B812-068 / design Coupling Guards). A regression is a blocker.
  [Story: FR-B812-068, NFR-B812-002]

- [x] **T-037** Sibling scan. Grep all harnesses in `.forge/scripts/tests/` for any
  that hard-assert the 2.0.0 backend subtree is server-only (no client adapter)
  or assert `transport_connect_client.rs.tmpl` is absent. Focus on:
  - `b8-6.test.sh` — the B.8.6 Connect-RPC harness. Check whether it asserts
    "server-only" or "no client template" against the 2.0.0 subtree. Landing
    `transport_connect_client.rs.tmpl` is ADDITIVE (new file) — b8-6's existing
    greps for server-side symbols should NOT break, but verify explicitly
    (`bash b8-6.test.sh --level 1` → exit 0).
  - Any harness with a repo-wide scan (`find .forge/templates/`) that hard-asserts
    a file count or absence-of-client in the 2.0.0 subtree.
  - Any harness referencing the 1.0.0 baseline span inventory with an assertion
    that would break if a new 2.0.0 golden is added alongside it.
  For each harness asserting an old (now-broken) state: fix the assertion to match
  the new additive reality and re-run to confirm GREEN. A regression in a sibling
  harness is a blocker (`shared-standard sibling-harness coupling` lesson).
  Record all harness names checked and their exit codes.
  [Story: NFR-B812-002, `shared-standard sibling-harness coupling` lesson,
   `full_harness_suite_before_push` lesson]

- [x] **T-038** Neutralize all `[NEEDS CLARIFICATION:]` markers in `specs.md`
  that were resolved by the ADRs and Phase 0 live evidence (b8-9/b8-10/b8-11
  precedent). Per `open-questions.md` anchor table:
  - FR-B812-031 marker (connectrpc client API, Q-003) → `Resolved by ADR-B812-003:
    connectrpc 0.6.x client API verified LIVE (evidence.md P-01/P-24); client
    feature flag confirmed in T-005/T-017 (CARRY-1); exact symbols pinned.`
  - FR-B812-041 marker (Envoy SecurityPolicy apiVersion, Q-002) → `Resolved by
    ADR-B812-002: gateway.envoyproxy.io/v1alpha1 SecurityPolicy verified LIVE
    (evidence.md P-03/T-008 CARRY-4); JWT folded into spec.jwt.providers[] (v1.8.x form).`
  - FR-B812-043 marker (Zitadel OIDC discovery URL, Q-002) → `Resolved by
    ADR-B812-002: /.well-known/openid-configuration discovery URL verified (P-04);
    jwks_uri extracted and pinned in T-006 (CARRY-2).`
  Do NOT modify `.omc/plans/*.md` (plan files are read-only).
  [Story: Article III.4, open-questions.md anchor table]

- [x] **T-039** Run the FULL ~51-harness suite
  (`for h in .forge/scripts/tests/*.test.sh; do bash "$h" --level 1; done`).
  Verify each harness exits 0. Pay attention to:
  - `b8-6.test.sh` — S2S Connect server template assertions (landing the client
    template is additive; must remain GREEN).
  - `b8-7.test.sh` — Envoy-OIDC / Zitadel assertions (no Envoy-OIDC template
    previously existed in 2.0.0 subtree; adding them should not break b8-7's guards).
  - `c1.test.sh` — c1 reference project assertions (committed c1 stays 1.0.0 per
    NFR-B812-010; c1 harness must remain GREEN).
  - `delivery.test.sh` — delivery scaffold repo-wide scan; confirm the new 2.0.0
    templates are under `N.N.N/` subtree and exempt from any scaffold-plan count.
  - Any harness whose repo-wide scan of `.forge/templates/` might pick up the
    new client template or Envoy-OIDC templates as unexpected additions.
  Versioned `N.N.N/` subtrees are exempt from repo-wide scans per scaffolding.md
  convention. Any regression is a blocker (NFR-B812-002).
  Record all harness names and exit codes.
  [Story: NFR-B812-002, `full_harness_suite_before_push` lesson]

- [x] **T-040** Flip `.forge/changes/b8-12-e2e-migration/.forge.yaml`:
  `status: planned → implemented` AND add `timeline.implemented: 2026-06-04`.
  Run `bash .forge/scripts/validate-change-yaml.sh
  .forge/changes/b8-12-e2e-migration/.forge.yaml` → exit 0. Then immediately
  **re-run POST-flip gates** (b8-coroot lesson: gates re-run AFTER the flip,
  not trusted from pre-flip run). Re-run at minimum:
  `b8-12.test.sh --level 1` (~23/~23), `b8-1.test.sh --level 1`,
  `b8-10.test.sh --level 1`, `b8-6.test.sh --level 1`, `validate-change-yaml.sh`,
  `verify.sh`, `constitution-linter.sh`. Record all outputs.
  [Story: Article V, b8-coroot lesson]

- [x] **T-041** Independent review pass (separate lane — author MUST NOT
  self-approve; NFR-B812-009; t5-2 self-validation lesson). The independent
  reviewer MUST re-execute (not trust the transcript):
  `b8-12.test.sh --level 1` (~23/~23), `b8-1.test.sh --level 1` (baseline
  invariants), `b8-10.test.sh --level 1` (migration driver), `b8-6.test.sh
  --level 1` (S2S server adapter frozen), `validate-standards-yaml.sh
  .forge/standards/`, `constitution-linter.sh` (OVERALL PASS), `verify.sh`,
  and the `[NEEDS CLARIFICATION:]` neutralization check on `specs.md`.
  The reviewer specifically re-confirms the verify-then-pin LIVE items
  (NFR-B812-005: connectrpc client API, Envoy SecurityPolicy apiVersion,
  Zitadel issuer) — NOT self-ruled by the author.
  Record the reviewer's name and run timestamp in the change record.
  [Story: NFR-B812-009, Article V.2, t5-2 lesson, b8-coroot lesson]

- [x] **T-042** Archive prep: verify all tasks marked complete, independent review
  PASS recorded, run `/forge:archive b8-12-e2e-migration` to flip status
  `implemented → archived`. Note: the implemented flip (T-040) occurs at the end
  of Phase 8; the archive flip occurs after the independent review PASS (T-041).
  [Story: Article V]

---

## FR-B812-* / NFR-B812-* Coverage Table

All 40 FRs + 10 NFRs covered (Spec-Delta-modified FRs mapped to their Now: text).

| FR / NFR | Now (Spec-Delta or original) | Task(s) |
|----------|------------------------------|---------|
| FR-B812-001 | Committed 2.0.0 golden span inventory present | T-013, T-030 |
| FR-B812-002 | 2.0.0 golden is SUPERSET of 1.0.0 baseline (3 spans) | T-013, T-014, T-030 |
| FR-B812-003 | Phantom user.interaction absent from both goldens | T-001, T-013, T-030 |
| FR-B812-004 | Goldens sanitised (ts:redacted, no IPv4) | T-013, T-030 |
| FR-B812-005 | Golden superset assertion via hermetic fake-OTLP diff -q | T-002, T-014, T-030 |
| FR-B812-006 | No committed p99 number in b8-12 change tree (scoped guard, not specs.md) | T-010 (T-017), T-027, T-030 |
| FR-B812-010 | L1 hermetic: Phase 0 dry-run exits 0 on 1.0.0 tmpdir copy | T-015, T-030 |
| FR-B812-011 | L1: dry-run plan output has additive-delta lines + no mutation | T-015, T-030 |
| FR-B812-012 | L1: committed c1 example git-clean after L1 | T-015, T-030 |
| FR-B812-013 | L2 opt-in: real Phase-2 overlay asserts additive result | T-011 (L2-01), T-031 |
| FR-B812-014 | L2: VIII.1/VIII.2 — Kong + Temporal + REST NOT removed | T-011 (L2-02), T-031 |
| FR-B812-015 | Exit-7 on wrong-version tmpdir | T-015, T-030 |
| FR-B812-020 | **Now**: 3 demo `.feature` files at demo-00{1,2,3}-*/features/ byte-intact (Spec Delta) | T-004, T-016, T-030 |
| FR-B812-021 | proto contracts byte-intact after overlay | T-004, T-016 |
| FR-B812-022 | **Now**: demo-004 status:specified at demo-004-user-onboarding/.forge.yaml (Spec Delta) | T-004, T-016, T-030 |
| FR-B812-023 | **Now**: 3 demo feature files (not 4) Given/When/Then structure intact (Spec Delta) | T-004, T-010 (T-009), T-030 |
| FR-B812-030 | transport_connect_client.rs.tmpl present in 2.0.0 subtree | T-018, T-020, T-030 |
| FR-B812-031 | Client template carries connectrpc =0.6.1 sentinel + CARRY-1 feature flag | T-005, T-017, T-018, T-019, T-030 |
| FR-B812-032 | Client template covers auth/TLS/deadline/retry posture | T-018, T-030 |
| FR-B812-033 | 1.0.0 server adapter transport_connect.rs.tmpl byte-UNCHANGED | T-017, T-010 (T-020), T-030 |
| FR-B812-034 | cargo-check gated behind FORGE_E2E_TOOLCHAINS L2 opt-in | T-011 (L2-04), T-031 |
| FR-B812-035 | transport.yaml versions_2_0_0 + connectrpc =0.6.1 pin | T-010 (T-013), T-030 |
| FR-B812-040 | Envoy-OIDC templates present in 2.0.0 infra/k8s/envoy-gateway/ subtree | T-022, T-025, T-030 |
| FR-B812-041 | SecurityPolicy apiVersion verify-then-pin LIVE (not fabricated) | T-008, T-021, T-022, T-038 |
| FR-B812-042 | Backend JWT middleware template present in 2.0.0 backend/ subtree | T-023, T-025, T-030 |
| FR-B812-043 | Zitadel discovery URL verify-then-pin LIVE (CARRY-2) | T-006, T-021, T-022, T-038 |
| FR-B812-044 | identity.yaml@1.1.0 cross-reference in Envoy-OIDC templates | T-022, T-025, T-030 |
| FR-B812-045 | 1.0.0 infra/k8s/ Kong paths byte-UNCHANGED | T-022, T-010 (T-020), T-030 |
| FR-B812-050 | Methodology doc present in docs/MIGRATIONS.md + B.8.13 anchor | T-026, T-027, T-030 |
| FR-B812-051 | No committed numeric p99 latency in methodology doc | T-026, T-027, T-030 |
| FR-B812-052 | FORGE_B8_12_LIVE opt-in methodology leg skip-passes without toolchains | T-011 (L2-03), T-031 |
| FR-B812-060 | Harness file b8-12.test.sh created + executable + audit header | T-009, T-030 |
| FR-B812-061 | Harness structure: --level, _helpers.sh, run_test/print_summary | T-009, T-030 |
| FR-B812-062 | L1 hermetic ~23 tests ≤ a few seconds wall-clock | T-009, T-010, T-012, T-030 |
| FR-B812-063 | fake-OTLP collector stdlib-only guard in harness | T-002, T-010 (T-019), T-030 |
| FR-B812-064 | L2 FORGE_B8_12_LIVE real migrate + assertion block | T-011 (L2-01/L2-03), T-031 |
| FR-B812-065 | L2 FORGE_E2E_TOOLCHAINS cargo-check | T-011 (L2-04), T-031 |
| FR-B812-066 | forge-ci.yml registers b8-12.test.sh after b8-11 | T-029, T-030 |
| FR-B812-067 | CHANGELOG [Unreleased] entry anchored b8-12-e2e-migration | T-028, T-030 |
| FR-B812-068 | Coupling guards: b8-1 + b8-10 exit 0 | T-010 (T-023), T-036, T-030 |
| NFR-B812-001 | L1 wall-clock ≤ a few seconds hermetic | T-009, T-012, T-030 |
| NFR-B812-002 | Full ~51-harness suite GREEN pre-push | T-036, T-037, T-039 |
| NFR-B812-003 | Frozen 1.0.0 templates + committed c1 example byte-identity | T-010 (T-008/T-020), T-030, T-039 |
| NFR-B812-004 | NO committed latency number (III.4 + ADR-B8-1-002) | T-010 (T-017), T-027, T-030 |
| NFR-B812-005 | Verify-then-pin LIVE: connectrpc client API + Envoy API + Zitadel issuer | T-005, T-006, T-007, T-008, T-017, T-021, T-041 |
| NFR-B812-006 | Goldens deterministic (ts:redacted, no IPv4, byte-stable) | T-013, T-010 (T-004), T-030 |
| NFR-B812-007 | Zero new external dep (stdlib collector only) | T-002, T-010 (T-019), T-030 |
| NFR-B812-008 | VIII.1/VIII.2 preserved (additive-only invariant) | T-010 (T-008/T-020), T-011 (L2-02), T-034 |
| NFR-B812-009 | Independent review before /forge:archive | T-041 |
| NFR-B812-010 | Committed c1 stays 1.0.0 throughout B.8.12 lifecycle | T-010 (T-008), T-030, T-039 |
