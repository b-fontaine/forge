# Tasks: j8-janus-rules
<!-- Status: implemented -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-J8-XXX]` (Article V.1) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/j8.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` are honored verbatim ; deviations require
  a new ADR.
- Concrete pins / format / exit codes resolved in `design.md`
  ADR-J8-001..007 ; impl Phase 1 RED witnesses are written first.

---

## Phase 1 — Foundation : RED harness + helper skeleton

Goal : `j8.test.sh` exists with **18 L1 + 2 L2** stubs all FAIL ;
`bin/_forge-init-helpers.sh` skeleton exists ; full RED state
captured ; CI registration done.

### T-PHA — j8.test.sh skeleton

- [x] **T-PHA-001** : Create `.forge/scripts/tests/j8.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL counters
      reset, `--level 1,2` parsing, `print_summary` close-out.
      Mirror the J.7 / T.5-OTel layout. [Story: FR-J8-100]
- [x] **T-PHA-002** : Add **18 L1 test stubs** returning
      `_not_implemented` covering the 18 anchor IDs enumerated in
      `design.md` § "L1 unit-level" table. [Story: FR-J8-101]
- [x] **T-PHA-003** [P] : Add **2 L2 fixture stubs**
      (`_test_j8_l2_sbom_good`, `_test_j8_l2_sbom_determinism`)
      using `mk_tmpdir_with_trap`. [Story: FR-J8-102]
- [x] **T-PHA-004** [P] : Register `j8.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t5-otel.test.sh` with `--level 1,2`.
      [Story: FR-J8-100]
- [x] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/j8.test.sh --level 1,2 > /tmp/j8-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 20 / Passed: 0`. [Story: FR-J8-101]

### T-HLP — Wrapper helper skeleton (`bin/_forge-init-helpers.sh`)

- [x] **T-HLP-001** : Create `bin/_forge-init-helpers.sh` with
      bash header + `# shellcheck shell=bash` + audit comment.
      Empty function `_refuse_if_forbidden() { :; }` placeholder
      (filled in T-JAN-007). [Story: FR-J8-022 / ADR-J8-005]

**Phase 1 exit gate** : `j8.test.sh --level 1,2` exits 1 with
`FAIL ≥ 20`, `forge-ci.yml` matrix updated, helper skeleton in
place. constitution-linter.sh OVERALL PASS.

---

## Phase 2 — J.8.a : Janus refusal rules

Goal : Janus agent + dispatch-table + helper + standard all ship.
After this phase, 7 L1 tests flip GREEN (3 Janus + 3 dispatch-table
+ 4 helper/dispatcher refusal — counted with overlap).

### T-JAN — Janus agent forbidden-archetypes section

- [x] **T-JAN-001** : RED witness — convert
      `_test_j8_001_janus_section` + `_test_j8_002_janus_rule_001`
      + `_test_j8_003_janus_rule_002_003`. [Story: FR-J8-001..005]
- [x] **T-JAN-002** : Edit
      `.claude/agents/cross-layer-orchestrator.md` to add a new H2
      section "Forbidden archetypes & combinations" placed BETWEEN
      "Dispatch Table" (line 21) and "12-Step Workflow" (line 35).
      Section MUST include :
      - `<!-- Audit: J.8 (j8-janus-rules) -->` HTML comment anchor.
      - Numbered enumeration of `J8-RULE-001` (flutter-firebase
        Schrems II + CLOUD Act + alternative `default + Firebase
        overlay`), `J8-RULE-002` (T3 ⇒ self-host Zitadel), and
        `J8-RULE-003` (T3 ⇒ self-host SigNoz + no Datadog).
      - Each rule cites : (a) one-line rationale, (b) ADR /
        standard ref, (c) alternative path.
      - Cross-link to `dispatch-table.yml::forbidden_archetypes`
        + new standard `global/janus-orchestration-rules.md`.
      - One paragraph stating Janus invokes the dispatcher
        refusal logic BEFORE any layer-specific routing
        (FR-J8-004).
      [Story: FR-J8-001..005 / ADR-J8-004]
- [x] **T-JAN-003** : Run `j8.test.sh` ; expect 3 Janus L1 tests
      flip GREEN. [Story: FR-J8-001..005]

### T-DT — dispatch-table forbidden-archetypes list

- [x] **T-DT-001** : RED witness — convert
      `_test_j8_010_dispatch_forbidden` +
      `_test_j8_011_entry_shape` +
      `_test_j8_012_seed_flutter_firebase`.
      [Story: FR-J8-010..012]
- [x] **T-DT-002** : Edit `.forge/scaffolding/dispatch-table.yml`
      to add a top-level `forbidden_archetypes:` list with the
      `flutter-firebase` seed entry per FR-J8-012 :
      ```yaml
      forbidden_archetypes:
        - name: flutter-firebase
          reason: "Schrems II + CLOUD Act incompatibles avec positionnement EU/premium Forge"
          since: "0.4.0-rc.1"
          alternative: "default archetype + add Firebase as adopter-managed overlay (out of Forge scope)"
          rule_id: J8-RULE-001
      ```
      Header comment block extended with the J.8 audit reference.
      [Story: FR-J8-010..013 / ADR-J8-004]
- [x] **T-DT-003** : Run `j8.test.sh` ; expect 3 dispatch-table
      L1 tests flip GREEN. [Story: FR-J8-010..012]

### T-HLP — `_forge-init-helpers.sh` refusal logic

- [x] **T-HLP-002** : RED witness — convert
      `_test_j8_020_helper_exists` +
      `_test_j8_021_wrapper_sources_helper` +
      `_test_j8_023_refusal_format`. [Story: FR-J8-022 / FR-J8-021]
- [x] **T-HLP-003** : Implement `_refuse_if_forbidden()` in
      `bin/_forge-init-helpers.sh` per ADR-J8-005 (Python 3 inline
      reads `dispatch-table.yml`, matches archetype against
      `forbidden_archetypes[*].name`, emits structured stderr
      `[REFUSAL: <archetype>: <rule_id>: <reason> ; alternative: <alt>]`,
      exits 3). [Story: FR-J8-021..023 / ADR-J8-003 / ADR-J8-005]
- [x] **T-HLP-004** : Edit `bin/forge-init-fsm.sh` to source
      `_forge-init-helpers.sh` at the top + invoke
      `_refuse_if_forbidden "full-stack-monorepo"` as the first
      action. [Story: FR-J8-022]
- [x] **T-HLP-005** [P] : Same edit on `bin/forge-init-mobile-only.sh`.
      [Story: FR-J8-022]
- [x] **T-HLP-006** : Run `j8.test.sh` ; expect 3 helper-related
      L1 tests flip GREEN. [Story: FR-J8-020..022]

### T-DSP — TS dispatcher refusal check

- [x] **T-DSP-001** : RED witness — convert
      `_test_j8_022_dispatcher_check`. [Story: FR-J8-020]
- [x] **T-DSP-002** : Edit `cli/src/commands/init-archetype.ts`
      (or the dispatcher entrypoint located at impl time) to read
      `dispatch-table.yml::forbidden_archetypes` BEFORE invoking
      any wrapper. On match → exit 3 + structured stderr per
      FR-J8-021 format. NFR-J8-006 strict mode preserved (no
      `any`, no `@ts-ignore`). [Story: FR-J8-020..023 / NFR-J8-006]
- [x] **T-DSP-003** : Run `j8.test.sh` ; expect dispatcher L1 test
      flip GREEN. [Story: FR-J8-020]

### T-STD — janus-orchestration-rules.md standard

- [x] **T-STD-001** : RED witness — convert
      `_test_j8_030_standard_exists`. [Story: FR-J8-030]
- [x] **T-STD-002** : Create
      `.forge/standards/global/janus-orchestration-rules.md` with
      ≥ 5 H2 sections per FR-J8-030 : Purpose, Rule catalogue
      (J8-RULE-XXX table), Adoption path, Refusal vs warning
      semantics, Extending the catalogue. [Story: FR-J8-030]
- [x] **T-STD-003** [P] : Register in `.forge/standards/index.yml`
      under triggers like `[scaffolding, refusal, forbidden,
      schrems, cloud-act]`. [Story: FR-J8-030]
- [x] **T-STD-004** : Run `j8.test.sh` ; expect standard L1 test
      flip GREEN. [Story: FR-J8-030]

**Phase 2 exit gate** : 11 L1 tests GREEN (Janus 3 + dispatch 3 +
helper/dispatcher 4 + standard 1). `verify.sh` aggregate up by
≥ 1 PASS (the new standards entry). constitution-linter.sh OVERALL
PASS. j7.test.sh + a7.test.sh unchanged.

---

## Phase 3 — J.8.b : `--eu-tier` flag + T3 enforcement + tier ledger

Goal : CLI flag plumbing + wrapper T3 rules + ledger ship. After
this phase, 5 L1 tests flip GREEN (3 flag + 1 T3 + 1 ledger).

### T-CLI — `--eu-tier` flag in `init.ts`

- [x] **T-CLI-001** : RED witness — convert
      `_test_j8_040_eu_tier_flag` + `_test_j8_041_eu_tier_validation`
      + `_test_j8_042_no_default`. [Story: FR-J8-040..042 / NFR-J8-002]
- [x] **T-CLI-002** : Edit `cli/src/commands/init.ts` to declare
      the `--eu-tier <tier>` flag (TS strict). Add to the existing
      flag-parsing infrastructure mirroring `--archetype` shape.
      [Story: FR-J8-040 / NFR-J8-006]
- [x] **T-CLI-003** : Implement validation against
      `.forge/schemas/compliance-tier.schema.json` enum
      `[T1, T2, T3]`. Invalid value → exit 2 + error pointing to
      the schema. [Story: FR-J8-041]
- [x] **T-CLI-004** : Pass validated tier to wrapper via env var
      `FORGE_EU_TIER=<tier>` (empty when absent). [Story: FR-J8-043]
- [x] **T-CLI-005** [P] : Implement soft warning per ADR-J8-002 :
      when `--eu-tier` absent AND `.forge/.forge-tier` not present
      in target tree, emit `[INFO: --eu-tier not set ...]` to
      stderr. Suppressible via `FORGE_EU_TIER_QUIET=1`.
      [Story: FR-J8-042 / ADR-J8-002]
- [x] **T-CLI-006** [P] : Add wizard prompt when `--wizard` is
      invoked, asking for the EU tier with default "skip".
      [Story: FR-J8-045]
- [x] **T-CLI-007** : Update Vitest unit tests (`cli/test/...`) to
      cover the new flag (validation, env-var passthrough, warning).
      [Story: NFR-J8-006]
- [x] **T-CLI-008** : Run `j8.test.sh` ; expect 3 flag L1 tests
      flip GREEN. [Story: FR-J8-040..042]

### T-T3 — T3 enforcement in `forge-init-fsm.sh`

- [x] **T-T3-001** : RED witness — convert
      `_test_j8_050_t3_self_host_zitadel`. [Story: FR-J8-050..054]
- [x] **T-T3-002** : Edit `bin/forge-init-fsm.sh` to read
      `$FORGE_EU_TIER` post-helper-source. Apply T3 rules when
      tier == T3 :
      - Refuse `identity_provider != zitadel-self-hosted`
        (FR-J8-051) — guard via grep on rendered identity config.
      - Refuse SigNoz Cloud SaaS endpoints (FR-J8-052) — guard via
        grep on rendered observability config for `signoz.io`.
      - Verify no Datadog in collector exporters (FR-J8-053).
      Each refusal exits 3 + structured `[REFUSAL: ...]` stderr.
      [Story: FR-J8-050..053 / ADR-J8-003]
- [x] **T-T3-003** [P] : Add T1 / T2 informational `[INFO: <tier>: ...]`
      stdout lines (FR-J8-054). No refusal at T1 / T2.
      [Story: FR-J8-054]
- [x] **T-T3-004** : Run `j8.test.sh` ; expect T3 L1 test flip
      GREEN. [Story: FR-J8-050..054]

### T-LED — `.forge-tier` ledger

- [x] **T-LED-001** : RED witness — convert
      `_test_j8_060_tier_ledger`. [Story: FR-J8-060]
- [x] **T-LED-002** : Edit `bin/forge-init-fsm.sh` post-scaffold
      step : when `$FORGE_EU_TIER` is non-empty, write
      `<target>/.forge/.forge-tier` containing exactly one line
      `<tier>\n` per ADR-J8-006 plain-text convention.
      [Story: FR-J8-060 / ADR-J8-006]
- [x] **T-LED-003** [P] : Same edit on
      `bin/forge-init-mobile-only.sh` (T3 rules don't apply yet
      to mobile-only — but the ledger should still record the
      declared tier for downstream consistency).
      [Story: FR-J8-060]
- [x] **T-LED-004** : Run `j8.test.sh` ; expect ledger L1 test
      flip GREEN. [Story: FR-J8-060]

**Phase 3 exit gate** : 5 additional L1 tests GREEN (cumulative 16).
`verify.sh` unchanged. CLI Vitest suite passes.

---

## Phase 4 — J.8.d : SBOM script + standard + CI workflow

Goal : `forge-sbom.sh` + standard + CI job ship. After this phase,
remaining 2 L1 tests flip GREEN (sbom signature + sbom-policy
standard) AND the 2 L2 fixtures flip GREEN.

### T-SBM — `bin/forge-sbom.sh` script + Python engine

- [x] **T-SBM-001** : RED witness — convert
      `_test_j8_070_sbom_signature`. [Story: FR-J8-070]
- [x] **T-SBM-002** : Create `bin/forge-sbom.sh` with bash header
      (`#!/usr/bin/env bash`, `set -uo pipefail`), `case` arg
      parsing for `--output <path>`, `--format json|xml`,
      `--target <dir>` (defaults : `sbom.cdx.json`, `json`,
      `$(pwd)`). Exit 2 on usage error. [Story: FR-J8-070 / NFR-J8-004]
- [x] **T-SBM-003** : Implement Python 3 inline engine via
      `python3 - <<'PY' ... PY` invocation per ADR-J8-007. Phase 1
      detection : walk `--target` for `Cargo.lock` / lockfiles
      (npm / pubspec). At least one MUST be present, else exit 1.
      [Story: FR-J8-071]
- [x] **T-SBM-004** [P] : Phase 2 parsers — TOML stdlib `tomllib`
      (Python ≥ 3.11) for Cargo, JSON stdlib for npm / pnpm /
      yarn lockfiles, PyYAML for pubspec. Each parser returns a
      flat list of `(name, version, purl)` tuples.
      [Story: FR-J8-073]
- [x] **T-SBM-005** : Phase 3 emit JSON minimum-viable CycloneDX
      1.5 per ADR-J8-001 :
      - `bomFormat`, `specVersion: "1.5"`, `serialNumber:
        "urn:uuid:<v4>"`, `version: 1`.
      - `metadata.timestamp` : `SOURCE_DATE_EPOCH` ?? `now()` ISO
        8601.
      - `metadata.tools` : `[{"name": "forge-sbom.sh", "version":
        "0.1.0"}]`.
      - `metadata.component` : application root from target dir
        manifest (Cargo.toml / package.json / pubspec.yaml).
      - `components[]` : sorted by `purl`, deduped.
      - `json.dumps(..., sort_keys=True, indent=2)` for
        determinism (FR-J8-075). [Story: FR-J8-072..075 / ADR-J8-001]
- [x] **T-SBM-006** [P] : Phase 3 emit XML when `--format xml` —
      handcraft via `xml.etree.ElementTree` covering same
      components. [Story: FR-J8-074]
- [x] **T-SBM-007** : Run `j8.test.sh --level 1` ; expect SBOM
      signature L1 test flip GREEN. [Story: FR-J8-070..076]

### T-PLC — `sbom-policy.md` standard

- [x] **T-PLC-001** : RED witness — convert
      `_test_j8_080_sbom_policy_standard`. [Story: FR-J8-080]
- [x] **T-PLC-002** : Create
      `.forge/standards/global/sbom-policy.md` with ≥ 4 H2
      sections per FR-J8-080 : Purpose & EU compliance rationale
      (NIS2 / DORA / CRA cross-link), Format choice (CycloneDX 1.5
      over SPDX 2.3 — sourced citation to upstream EU compliance
      guidance), Regeneration cadence (every release + on-demand),
      Out-of-scope (no signing / no transparency log this change ;
      future J.8 extension may add). [Story: FR-J8-080]
- [x] **T-PLC-003** [P] : Register in
      `.forge/standards/index.yml` under triggers like
      `[sbom, supply-chain, nis2, dora, cra, cyclonedx]`.
      [Story: FR-J8-080]
- [x] **T-PLC-004** : Run `j8.test.sh` ; expect sbom-policy L1
      test flip GREEN. [Story: FR-J8-080]

### T-L2 — L2 fixture tests for SBOM

- [x] **T-L2-001** : RED witness — convert
      `_test_j8_l2_sbom_good`. [Story: FR-J8-102]
- [x] **T-L2-002** : Implement L2 good fixture — temp dir with
      synthetic minimal `Cargo.lock` (1–2 deps) +
      `package-lock.json` (1 dep) ; run `forge-sbom.sh
      --target <tmpdir> --output <tmpdir>/sbom.cdx.json` ; assert
      exit 0, file exists, JSON contains `bomFormat:
      "CycloneDX"`, `specVersion: "1.5"`, ≥ 2 components in
      `components[]`. [Story: FR-J8-102 / FR-J8-072]
- [x] **T-L2-003** : RED witness — convert
      `_test_j8_l2_sbom_determinism`. [Story: FR-J8-102 / FR-J8-075]
- [x] **T-L2-004** : Implement L2 determinism fixture — same temp
      dir as good fixture, run twice with `SOURCE_DATE_EPOCH=0`,
      assert byte-identical output (`diff` returns 0).
      [Story: FR-J8-075]
- [x] **T-L2-005** : Run `j8.test.sh --level 1,2` ; expect 18 L1
      + 2 L2 = 20/20 GREEN, ≤ 15 s wall-clock (NFR-J8-001).
      [Story: NFR-J8-001 / FR-J8-101..102]

### T-CI — CI workflow `sbom` job

- [x] **T-CI-001** : Edit `.github/workflows/forge-ci.yml` to
      add a new `sbom` job after `harness` that :
      - `runs-on: ubuntu-latest`
      - `needs: [harness]`
      - checks out the repo + sets up Python 3.11
      - runs `bash bin/forge-sbom.sh --target examples/forge-fsm-example/
        --output sbom.cdx.json`
      - uploads `sbom.cdx.json` via
        `actions/upload-artifact@v4` with `name: sbom-cyclonedx`
        and `if-no-files-found: error`.
      Triggered on PR + main pushes (existing workflow triggers).
      [Story: FR-J8-090]
- [x] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter unchanged (CI workflow YAML doesn't add to the
      forge gate count).
      [Story: NFR-J8-002]

**Phase 4 exit gate** : `j8.test.sh --level 1,2` 20/20 GREEN.
`verify.sh` aggregate increases by ≈ 2 (new standards). All ADRs
honored.

---

## Phase 5 — Quality : docs + CHANGELOG + review

### T-DOC — Documentation

- [x] **T-DOC-001** [P] : Add a new H2 section "Forbidden
      combinations" to `docs/ARCHETYPES.md` with a `J8-RULE-*`
      table cross-linking the standard. [Story: FR-J8-110]
- [x] **T-DOC-002** [P] : Document `--eu-tier` flag in the
      existing CLI doc (located at impl time — likely
      `docs/CLI.md` if present, else create `docs/CLI-FLAGS.md`)
      with semantics, example invocation, backward-compat note,
      pointer to `compliance-tier.schema.json`. [Story: FR-J8-111]
- [x] **T-DOC-003** [P] : Add `## [Unreleased]` entry in
      `CHANGELOG.md` covering the 3 sub-modules (J.8.a + J.8.b +
      J.8.d). [Story: FR-J8-112]

### T-REV — Quality review gate

- [x] **T-REV-001** : Run `/forge:review j8-janus-rules` driving
      the constitutional gate review : Articles I (TDD), III +
      III.4, IV (delta), V (audit trail), VIII (CI), IX
      (security/observability), XII (governance). Block if any
      returns VIOLATION. [Story: Article V]
- [x] **T-REV-002** : Run the full `verify.sh` once more on a
      clean checkout to confirm reproducibility.
      [Story: NFR-J8-002]
- [x] **T-REV-003** : Verify
      `bin/forge-questions.sh --change j8-janus-rules --status open`
      returns empty (Q-001..Q-003 all answered post-design).
      [Story: Article III.4]
- [x] **T-REV-004** : Smoke test 3 BDD scenarios from `specs.md`
      manually :
      - `forge init --archetype flutter-firebase` → exit 3 +
        `[REFUSAL: ...J8-RULE-001...]`.
      - `forge init --archetype full-stack-monorepo --eu-tier T3` →
        scaffold + `.forge/.forge-tier` written with `T3`.
      - `bin/forge-sbom.sh --target examples/forge-fsm-example/`
        twice with `SOURCE_DATE_EPOCH=0` → byte-identical output.
      [Story: Article II / FR-J8-021..023 / FR-J8-050..060 / FR-J8-075]

**Phase 5 exit gate (= change archival readiness)** :

- `j8.test.sh --level 1,2` ≥ 20 PASS / 0 FAIL / ≤ 15 s.
- `verify.sh` aggregate ≥ baseline + 2 PASS / 0 FAIL / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `j7.test.sh` 21/21 PASS unchanged.
- `t5-otel.test.sh` 14/14 PASS unchanged.
- `a7.test.sh` 29/0 PASS (snapshot regen if any new template
  shipped — none in this change, so no-op).
- `validate-standards-yaml.sh` exits 0 on the live tree (the new
  `janus-orchestration-rules.md` + `sbom-policy.md` are MD not
  YAML, so J.7 doesn't gate ; index.yml entries register them as
  triggers without YAML frontmatter constraints).
- `bin/forge-questions.sh --change j8-janus-rules --status open`
  empty.
- 3 BDD scenarios manually smoked.
- All FR-J8-001..112 + NFR-J8-001..006 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/ARCHETYPES.md` + CLI doc updated.

---

## Constitutional task review (per Article V)

| Task family | TDD order                            | Spec link                          | Architecture                                    |
|-------------|--------------------------------------|------------------------------------|-------------------------------------------------|
| T-PHA-*     | RED phase (intentional)              | FR-J8-100..102                     | N/A                                             |
| T-HLP-*     | RED witness then helper impl         | FR-J8-022 / ADR-J8-005             | shell-helper convention                         |
| T-JAN-*     | RED witness then agent edit          | FR-J8-001..005                     | ADR-J8-004 (rule ID format)                     |
| T-DT-*      | RED witness then dispatch-table edit | FR-J8-010..013                     | ADR-J8-004                                      |
| T-DSP-*     | RED witness then TS impl             | FR-J8-020..023 / NFR-J8-006        | ADR-J8-003 (exit code) + TS strict              |
| T-STD-*     | RED witness then standard MD         | FR-J8-030                          | global/standards-lifecycle.md                   |
| T-CLI-*     | RED witness then CLI impl            | FR-J8-040..045 / NFR-J8-002/006    | ADR-J8-002 (no default), b5.1 ABI               |
| T-T3-*      | RED witness then wrapper guard       | FR-J8-050..054                     | ADR-J8-003 (exit code)                          |
| T-LED-*     | RED witness then ledger write        | FR-J8-060                          | ADR-J8-006 (plain text)                         |
| T-SBM-*     | RED witness then sbom impl           | FR-J8-070..076 / NFR-J8-001/004/005| ADR-J8-001 (handcraft) + ADR-J8-007 (F.2 reuse) |
| T-PLC-*     | RED witness then standard MD         | FR-J8-080                          | global/standards-lifecycle.md                   |
| T-L2-*      | RED witness then fixture impl        | FR-J8-102 / FR-J8-075              | Eris fixture convention                         |
| T-CI-*      | Validation only                      | FR-J8-090 / NFR-J8-002             | forge-self-ci standard                          |
| T-DOC-*     | No code, doc-only                    | FR-J8-110..112                     | ARCHETYPES + CLI + CHANGELOG conventions        |
| T-REV-*     | Final gate, no production code       | Article V / II (BDD smoke)         | All articles                                    |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 6     | 2                    | 20 stubs      |
| 2     | 16    | 2                    | 7 (per cluster) |
| 3     | 16    | 4                    | 5 (per cluster) |
| 4     | 14    | 4                    | 4 (per cluster) |
| 5     | 7     | 3                    | 0 (validation only) |
| **Total** | **59** | **15** | **36 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1 h,
Phase 2 ≈ 4–5 h, Phase 3 ≈ 4–5 h, Phase 4 ≈ 4–5 h, Phase 5 ≈ 1 h.
Total ≈ 2 working days, consistent with the **L** complexity
estimate in `proposal.md`.
