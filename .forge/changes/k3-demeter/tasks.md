# Tasks: k3-demeter
<!-- Status: planned -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-K3-DEM-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/k3.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-K3-001..007) are honored verbatim ;
  deviations require a new ADR.
- All concrete pins / format / exit codes are resolved in
  `design.md` ; impl Phase 1 RED witnesses are written first.

---

## Phase 1 — Foundation : RED harness + data files skeleton

Goal : `k3.test.sh` exists with **20 L1 + 2 L2** stubs all FAIL ;
`.forge/data/cloud-act-publishers.yml` skeleton exists ; full
RED state captured ; CI registration done.

### T-PHA — k3.test.sh skeleton

- [ ] **T-PHA-001** : Create `.forge/scripts/tests/k3.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL counters
      reset, `--level 1,2` parsing, `print_summary` close-out.
      Mirror the J.8 / T.5-OTel layout. [Story: FR-K3-DEM-100]
- [ ] **T-PHA-002** : Add **20 L1 test stubs** returning
      `_not_implemented` covering the 20 anchor IDs enumerated in
      `design.md` § "L1 unit-level" table. [Story: FR-K3-DEM-101]
- [ ] **T-PHA-003** [P] : Add **2 L2 fixture stubs**
      (`_test_k3_l2_deny_list_hit`, `_test_k3_l2_clean_tree_t2`)
      using `mk_tmpdir_with_trap`. [Story: FR-K3-DEM-102]
- [ ] **T-PHA-004** [P] : Register `k3.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `j8.test.sh` with `--level 1,2`.
      [Story: FR-K3-DEM-100]
- [ ] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/k3.test.sh --level 1,2 > /tmp/k3-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 22 / Passed: 0`. [Story: FR-K3-DEM-101]

### T-DAT — Data file skeletons

- [ ] **T-DAT-001** : Create `.forge/data/cloud-act-publishers.yml`
      skeleton with frontmatter (`version: "1.0.0"`,
      `last_reviewed: "2026-05-10"`, `expires_at: "2027-05-10"`,
      `maintained_by: "BDFL (interim — see standards/global/data-stewardship-rules.md)"`)
      + empty `ecosystems: { cargo: [], npm: [], pub: [] }` +
      empty `pii_field_patterns: []`. Valid YAML, parseable by
      `python3 -c 'import yaml ; yaml.safe_load(open(...))'`.
      [Story: FR-K3-DEM-064 / NFR-K3-DEM-008 / ADR-K3-003]

**Phase 1 exit gate** : `k3.test.sh --level 1,2` exits 1 with
`FAIL ≥ 22`, `forge-ci.yml` matrix updated, publisher-list
skeleton in place. constitution-linter.sh OVERALL PASS.

---

## Phase 2 — K.3.a : Demeter persona file

Goal : `.claude/agents/demeter.md` ships with all 7 mandatory
H2 sections + audit comment + ≥ 5 K3-RULE entries. After this
phase, 9 L1 tests flip GREEN
(`_test_k3_001..009 + _test_k3_007 rule catalogue`).

### T-PER — Persona file skeleton

- [ ] **T-PER-001** : RED witness — convert `_test_k3_001_persona_exists`
      + `_test_k3_002_audit_comment` + `_test_k3_003_persona_h2`.
      [Story: FR-K3-DEM-001..003 / 010]
- [ ] **T-PER-002** : Create `.claude/agents/demeter.md` with :
      - `<!-- Audit: K.3 (k3-demeter) -->` HTML comment at top.
      - H1 `# Agent: Data Steward EU (Demeter)`.
      - H2 `## Persona` per FR-K3-DEM-002 (Name / Role / Style).
      - H2 `## Purpose` per FR-K3-DEM-003 (cite K.3 + I.4 + T.4
        compliance-tier.schema.json).
      [Story: FR-K3-DEM-001..003 / 010 / ADR-K3-001]
- [ ] **T-PER-003** : Run `k3.test.sh` ; expect 3 persona-skeleton
      L1 tests flip GREEN. [Story: FR-K3-DEM-001..003]

### T-CHK — Checklists section

- [ ] **T-CHK-001** : RED witness — convert `_test_k3_004_checklists_h2`
      + `_test_k3_005_checklists_items`. [Story: FR-K3-DEM-004]
- [ ] **T-CHK-002** : Add `## Checklists` H2 with 3 H3
      sub-sections :
      - **Data Classification** : ≥ 5 `[ ]` items mapping
        `compliance-tier.schema.json::x-tier-descriptions` to
        `ARCHITECTURE-TARGET §10.2` matrix rows (Verify : tier
        ledger ↔ flag consistency ; Check : component eligibility
        ; Exception : T1 with DPA).
      - **DPA Validation** : ≥ 5 `[ ]` items checking
        `.forge/.forge-dpa-declared` presence + date freshness +
        T1-flagged component coupling. [Story: FR-K3-DEM-040..044]
      - **CLOUD Act Exposure** : ≥ 5 `[ ]` items checking
        Cargo / npm / pubspec lockfile parsing + deny-list match
        + tier-scaled severity. [Story: FR-K3-DEM-060..074]
      Style mirrors `security-auditor.md::Checklists`.
      [Story: FR-K3-DEM-004 / 020..026 / 040..044 / 060..074]
- [ ] **T-CHK-003** : Run `k3.test.sh` ; expect 2 checklist L1
      tests flip GREEN. [Story: FR-K3-DEM-004]

### T-OUT — Output report shape

- [ ] **T-OUT-001** : RED witness — convert `_test_k3_006_output_h2`.
      [Story: FR-K3-DEM-005]
- [ ] **T-OUT-002** : Add `## Output: Data Stewardship Report`
      H2 documenting :
      - Summary table (Critical / High / Medium / Low /
        Informational counts).
      - Findings template per finding (`[SEVERITY] <K3-RULE-NNN>:
        <title>` + Category / Location / Evidence / Risk /
        Remediation / Verification).
      - Cleared Items section.
      - Overall status line (`BLOCKED` / `CONCERNS` / `CLEARED`)
        with severity gating (Critical or High → BLOCKED).
      Mirrors `security-auditor.md::Output: Security Report`.
      [Story: FR-K3-DEM-005 / 071 / 072]
- [ ] **T-OUT-003** : Run `k3.test.sh` ; expect 1 output-shape
      L1 test flip GREEN. [Story: FR-K3-DEM-005]

### T-CAT — Rule catalogue (K3-RULE-001..005)

- [ ] **T-CAT-001** : RED witness — convert `_test_k3_007_rule_catalogue`.
      [Story: FR-K3-DEM-006 / 120..124]
- [ ] **T-CAT-002** : Add `## Rule Catalogue` H2 with table
      enumerating K3-RULE-001..005 per FR-K3-DEM-120..124. Each
      row cites trigger, severity (tier-scaled where applicable),
      evidence pattern, remediation hint, ADR / standard
      cross-link. [Story: FR-K3-DEM-006 / 120..124 / ADR-K3-005]
- [ ] **T-CAT-003** [P] : Add `K3-RULE-006` (publisher-list
      staleness) in the same table per FR-K3-DEM-073.
      [Story: FR-K3-DEM-073 / ADR-K3-005]
- [ ] **T-CAT-004** : Run `k3.test.sh` ; expect rule-catalogue L1
      test flip GREEN. [Story: FR-K3-DEM-006]

### T-INT — Integration + Anti-Hallucination sections

- [ ] **T-INT-001** : RED witness — convert `_test_k3_008_integration`
      + `_test_k3_009_anti_halluc`. [Story: FR-K3-DEM-007 / 008]
- [ ] **T-INT-002** : Add `## Integration` H2 documenting :
      - Janus Step 9 dispatch (cross-link to
        `cross-layer-orchestrator.md` Step 9 narrative as
        renamed by ADR-K3-007).
      - Future `forge audit --compliance` CLI surface
        (ARCHITECTURE-TARGET §12.4 line 952 ; not yet shipped).
      - Sibling relationship to Aegis (data-stewardship vs
        vulnerability ; parallel passes).
      - Forward relationship to Themis (K.5, deferred T7) —
        consumes Demeter outputs at the regulatory-deadlines
        layer.
      [Story: FR-K3-DEM-007 / ADR-K3-007]
- [ ] **T-INT-003** : Add `## Anti-Hallucination Protocol` H2
      stating Article III.4 contract — emit
      `[NEEDS CLARIFICATION:]` and STOP when classification is
      ambiguous. Cite the 4 trigger conditions from
      NFR-K3-DEM-009 (multinational publisher, recent
      acquisition, tier ledger mismatch, undeclared tier).
      [Story: FR-K3-DEM-008 / 021 / 026 / NFR-K3-DEM-009]
- [ ] **T-INT-004** : Add file footer with the 6 audit
      cross-references per FR-K3-DEM-112 (ARCHITECTURE-TARGET
      §9.2 / §10 / §11.2 + new-archetypes-plan §1.4 / §7.1 /
      §9). [Story: FR-K3-DEM-011 / 112]
- [ ] **T-INT-005** : Run `k3.test.sh` ; expect integration +
      anti-hallucination L1 tests flip GREEN.
      [Story: FR-K3-DEM-007 / 008]

**Phase 2 exit gate** : 9 L1 tests GREEN (persona 3 + checklists
2 + output 1 + rule catalogue 1 + integration 1 +
anti-hallucination 1). `verify.sh` aggregate unchanged.
constitution-linter.sh OVERALL PASS.

---

## Phase 3 — K.3.b : Deterministic dependency scanner

Goal : `bin/forge-demeter-scan.sh` + Python engine + populated
publisher list ship. After this phase, 5 L1 tests flip GREEN
(`_test_k3_010..014`) AND the 2 L2 fixtures flip GREEN.

### T-PUB — Publisher list seed entries

- [ ] **T-PUB-001** : RED witness — convert
      `_test_k3_013_publisher_list_yaml` +
      `_test_k3_014_publisher_list_metadata`.
      [Story: FR-K3-DEM-064 / NFR-K3-DEM-008]
- [ ] **T-PUB-002** : Populate `.forge/data/cloud-act-publishers.yml`
      with seed entries per ADR-K3-003 :
      - `ecosystems.cargo` : ≥ 3 publishers (e.g. `aws-sdk-*`,
        `google-cloud-rust`, `azure-sdk-for-rust` lineage —
        check actual `crates.io` publisher-org names at impl
        time).
      - `ecosystems.npm` : ≥ 3 publishers (e.g. `@aws-sdk/*`,
        `@google-cloud/*`, `@azure/*`).
      - `ecosystems.pub` : ≥ 2 publishers (e.g.
        `firebase_*`, `cloud_firestore_*` and equivalent
        Firebase-ecosystem packages on `pub.dev`).
      Each entry carries `publisher`, `jurisdiction: "US"`,
      `evidence: <crates.io/npm/pub.dev URL>`.
      [Story: FR-K3-DEM-064..067 / ADR-K3-003]
- [ ] **T-PUB-003** [P] : Populate `pii_field_patterns` per
      ADR-K3-006 (≥ 25 patterns covering identity / financial /
      personal / contact / sensitive categories).
      [Story: FR-K3-DEM-123 / ADR-K3-006]
- [ ] **T-PUB-004** : Run `k3.test.sh` ; expect publisher-list
      L1 tests flip GREEN.
      [Story: FR-K3-DEM-064 / NFR-K3-DEM-008]

### T-SCN — Scanner script bash thin

- [ ] **T-SCN-001** : RED witness — convert
      `_test_k3_010_scanner_signature` +
      `_test_k3_011_scanner_exits` +
      `_test_k3_012_scanner_no_lockfile`.
      [Story: FR-K3-DEM-060..062]
- [ ] **T-SCN-002** : Create `bin/forge-demeter-scan.sh` with
      bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      `case` arg parsing for `--target <dir>`, `--tier
      T1|T2|T3`, `--output <path>`, `--format json|md`, `--help`.
      Defaults : `--target $(pwd)`, `--tier $(...)`,
      `--output demeter-report.json`, `--format json`. Exit 2
      on usage error.
      [Story: FR-K3-DEM-060..061 / NFR-K3-DEM-004 / ADR-K3-004]
- [ ] **T-SCN-003** : Add tier resolution logic — if `--tier`
      flag absent, read `<target>/.forge/.forge-tier` ;
      if absent emit `[NEEDS CLARIFICATION:]` per FR-K3-DEM-021
      and exit 1 with structured JSON to stdout.
      [Story: FR-K3-DEM-021 / 026 / 061]
- [ ] **T-SCN-004** : Add lockfile detection (depth ≤ 3) — if
      no lockfile, exit 2 with diagnostic. [Story: FR-K3-DEM-062]

### T-PYE — Python engine inline

- [ ] **T-PYE-001** : Implement Phase 1 (detect) — Python 3
      inline via `python3 - <<'PY' ... PY`. Walk `--target`
      depth ≤ 3, build `(ecosystem, path)` tuples for
      `Cargo.lock`, `package-lock.json`, `pnpm-lock.yaml`,
      `yarn.lock`, `pubspec.lock`. Log to `metadata.lockfiles_found`
      in the JSON report. [Story: FR-K3-DEM-062 / ADR-K3-004]
- [ ] **T-PYE-002** [P] : Implement Phase 2 (parsers) :
      - Cargo : `tomllib` stdlib (Python ≥ 3.11) parses
        `Cargo.lock` `[[package]]` blocks → `(name, version,
        source)` tuples.
      - npm : `json` stdlib parses `package-lock.json` v2/v3
        `packages` map → `(name, version, resolved)` tuples ;
        for `pnpm-lock.yaml` use `yaml` parser ;
        `yarn.lock` parsed via line-based regex (legacy
        format).
      - pubspec : `yaml.safe_load(...)` parses `pubspec.lock`
        `packages` map → `(name, version, description)` tuples.
      Each parser returns a uniform `[(ecosystem, name, version,
      publisher_hint), ...]` list. [Story: FR-K3-DEM-065..067]
- [ ] **T-PYE-003** : Implement Phase 3 (match + classify) —
      load `.forge/data/cloud-act-publishers.yml`, match each
      `(ecosystem, name, publisher_hint)` against
      `ecosystems.<ecosystem>` deny-list. Hit → emit
      `K3-RULE-001` finding ; tier-scaled severity per
      FR-K3-DEM-068. Cargo workspace drift → `K3-RULE-005`. DPA
      undeclared at T1 → `K3-RULE-002`. Publisher list stale
      → `K3-RULE-006`.
      [Story: FR-K3-DEM-068 / 120..124]
- [ ] **T-PYE-004** [P] : Implement DPA check — when
      `tier == T1`, read
      `<target>/.forge/.forge-dpa-declared` (single line plain
      text) ; missing or stale (date > 13 months old) emits
      `K3-RULE-002` finding. [Story: FR-K3-DEM-040..044 / 121 /
      ADR-K3-002]
- [ ] **T-PYE-005** : Implement Phase 4 (emit) — assemble JSON
      report per FR-K3-DEM-071 schema ; sort findings by
      `(severity_rank, rule_id, evidence)` ; `json.dumps(...,
      sort_keys=True, indent=2)` for determinism ;
      `metadata.timestamp = SOURCE_DATE_EPOCH ?? now()`.
      [Story: FR-K3-DEM-071 / NFR-K3-DEM-005]
- [ ] **T-PYE-006** [P] : Implement Markdown emit when
      `--format md` — handcraft Markdown mirroring Aegis output
      template per FR-K3-DEM-072.
      [Story: FR-K3-DEM-072]
- [ ] **T-PYE-007** : Implement offline-mode fallback — when
      network unreachable / `crates.io` cache absent, fall back
      to deny-list-only classification ; set
      `metadata.coverage_mode: "offline-deny-list-only"`.
      [Story: FR-K3-DEM-070 / NFR-K3-DEM-006]
- [ ] **T-PYE-008** : Implement exit-code mapping (0 / 1 / 2 / 3)
      per FR-K3-DEM-061. [Story: FR-K3-DEM-061]
- [ ] **T-PYE-009** : Run `k3.test.sh --level 1` ; expect
      scanner-signature + exit-codes + no-lockfile L1 tests flip
      GREEN. [Story: FR-K3-DEM-060..074]

### T-L2 — L2 fixture tests

- [ ] **T-L2-001** : RED witness — convert `_test_k3_l2_deny_list_hit`
      + `_test_k3_l2_clean_tree_t2`. [Story: FR-K3-DEM-102]
- [ ] **T-L2-002** : Implement L2 deny-list-hit fixture — temp
      dir with synthetic minimal `Cargo.lock` (1 EU crate +
      1 deny-listed `aws-sdk-*` crate) +
      `.forge/.forge-tier` = `T3` ; run scanner ; assert exit 3,
      JSON `overall_status: "BLOCKED"`, ≥ 1 K3-RULE-001 finding
      severity `Critical`, evidence cites the AWS crate name.
      [Story: FR-K3-DEM-102 / 068 / 120]
- [ ] **T-L2-003** : Implement L2 clean-tree-t2 fixture — temp
      dir with synthetic `Cargo.lock` (2 EU-only crates) +
      `package-lock.json` (1 EU dep) + `.forge/.forge-tier` =
      `T2` ; run scanner once ; assert exit 0,
      `overall_status: "CLEARED"`, 0 findings ; run scanner
      again with `SOURCE_DATE_EPOCH=0` ; assert byte-identical
      output (`diff` exits 0).
      [Story: FR-K3-DEM-102 / NFR-K3-DEM-005]
- [ ] **T-L2-004** : Run `k3.test.sh --level 1,2` ; expect
      ≥ 22 L1+L2 tests GREEN, ≤ 20 s wall-clock per
      NFR-K3-DEM-001. [Story: NFR-K3-DEM-001 / FR-K3-DEM-101..102]

**Phase 3 exit gate** : 5 L1 + 2 L2 = 7 tests flip GREEN
(cumulative 16 GREEN). Scanner script ships, publisher list
seeded, BDD scenarios 1 and 3 are now reproducible from L2
fixtures.

---

## Phase 4 — K.3.c : Standards + dispatch integration

Goal : new standard ships, index registered, Janus delta-edited,
CLAUDE.md trigger row added. After this phase, the remaining 5
L1 tests flip GREEN (`_test_k3_015..019, _test_k3_020`).

### T-STD — `data-stewardship-rules.md` standard

- [ ] **T-STD-001** : RED witness — convert
      `_test_k3_015_standard_exists`. [Story: FR-K3-DEM-083]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/data-stewardship-rules.md` with
      ≥ 5 H2 sections per FR-K3-DEM-083 :
      - Purpose (cite Schrems II + CLOUD Act + RGPD).
      - Rule catalogue (K3-RULE-NNN table mirroring
        `janus-orchestration-rules.md::Rule catalogue`).
      - Adoption path (how to integrate Demeter into a CI
        pipeline before I.5 ships ; references the
        forthcoming `forge-compliance.yml` workflow).
      - DPA declaration semantics (cite ADR-K3-002 ;
        `.forge/.forge-dpa-declared` ledger format with
        worked example).
      - Extending the catalogue (mirror the
        `janus-orchestration-rules.md` "Extending the
        catalogue" pattern : new K3-RULE-NNN entry + ADR / standard
        ref + adoption path + test coverage).
      - Regeneration cadence (cite ADR-K3-003 Phase A / B
        governance — BDFL/12-month interim, Themis/6-month
        post-T7).
      [Story: FR-K3-DEM-083 / ADR-K3-002 / 003 / 005]
- [ ] **T-STD-003** : Run `k3.test.sh` ; expect standard L1 test
      flip GREEN. [Story: FR-K3-DEM-083]

### T-IDX — Standards index registration

- [ ] **T-IDX-001** : RED witness — convert
      `_test_k3_016_index_registered`. [Story: FR-K3-DEM-082]
- [ ] **T-IDX-002** : Edit `.forge/standards/index.yml` to add :
      ```yaml
      - id: global/data-stewardship-rules
        path: standards/global/data-stewardship-rules.md
        triggers: [demeter, data-steward, dpa, cloud-act, schrems, t1, t2, t3, dependency-jurisdiction, k3-rule]
        scope: all
        priority: high
      ```
      Insert under the "Cross-Cutting Standards (new)" section
      adjacent to the J.8 entries for ordering coherence.
      [Story: FR-K3-DEM-082]
- [ ] **T-IDX-003** : Run `k3.test.sh` ; expect index L1 test
      flip GREEN. [Story: FR-K3-DEM-082]

### T-JAN — Janus delta edit (ADR-K3-007)

- [ ] **T-JAN-001** : RED witness — convert
      `_test_k3_017_janus_dispatch_row` +
      `_test_k3_018_janus_step9_modified`.
      [Story: FR-K3-DEM-080..081 / ADR-K3-007]
- [ ] **T-JAN-002** : Edit `.claude/agents/cross-layer-orchestrator.md`
      Dispatch Table — insert Demeter row AFTER the Aegis row
      and BEFORE the closing `---` of the table per the exact
      block in ADR-K3-007. Do NOT modify any other row.
      [Story: FR-K3-DEM-080 / ADR-K3-007]
- [ ] **T-JAN-003** : Edit Step 9 H3 :
      - Rename `### Step 9 — Security Pass (Aegis)` →
        `### Step 9 — Security & Data-Stewardship Pass (Aegis + Demeter)`.
      - Existing Aegis paragraph **unchanged**.
      - Append new Demeter paragraph per the verbatim block in
        ADR-K3-007.
      [Story: FR-K3-DEM-081 / ADR-K3-007]
- [ ] **T-JAN-004** [P] : Edit Quality Gates H2 — add a
      one-bullet entry "Data-stewardship gate — dispatched to
      **Demeter** at step 9 alongside Aegis."
      [Story: FR-K3-DEM-081 / ADR-K3-007]
- [ ] **T-JAN-005** [P] : Edit Constitution compliance H2 — add
      one bullet citing data-stewardship as cross-layer surface
      (article reference per ADR-K3-007 closing — IX.6 + XII).
      [Story: FR-K3-DEM-081 / ADR-K3-007]
- [ ] **T-JAN-006** : Run `k3.test.sh` ; expect 2 Janus L1 tests
      flip GREEN. [Story: FR-K3-DEM-080..081]

### T-CLM — CLAUDE.md trigger row

- [ ] **T-CLM-001** : RED witness — convert
      `_test_k3_019_claude_md_trigger`. [Story: FR-K3-DEM-084]
- [ ] **T-CLM-002** : Edit repo-level `CLAUDE.md` agent
      delegation table — insert :
      ```markdown
      | Data stewardship | **Demeter** | Data Steward EU |
      ```
      Alphabetically between `AI features (Oracle)` and
      `Domain modeling (Socrates)` per FR-K3-DEM-084. If the
      agent table is in a fragment file (e.g.
      `.claude/skills/forge/agents.md` or similar), edit that
      file instead — exact location locked at impl time.
      [Story: FR-K3-DEM-084]
- [ ] **T-CLM-003** : Run `k3.test.sh` ; expect CLAUDE.md L1
      test flip GREEN. [Story: FR-K3-DEM-084]

### T-NSC — Namespace collision guard

- [ ] **T-NSC-001** : RED witness — convert
      `_test_k3_020_no_namespace_collision`. [Story: FR-K3-DEM-086]
- [ ] **T-NSC-002** : Verify (no edit needed if invariant holds)
      that `grep -r "K3-RULE" .claude/agents/cross-layer-orchestrator.md
      .forge/standards/global/janus-orchestration-rules.md
      bin/_forge-init-helpers.sh` returns empty (the J.8
      surfaces never reference K3-RULE) AND that
      `grep -r "J8-RULE" .claude/agents/demeter.md
      .forge/standards/global/data-stewardship-rules.md
      bin/forge-demeter-scan.sh` returns empty (the K.3
      surfaces never reference J8-RULE except as cross-link
      acknowledgement). The harness test asserts both
      directions. [Story: FR-K3-DEM-086 / ADR-K3-005]
- [ ] **T-NSC-003** : Run `k3.test.sh --level 1,2` ; expect
      ALL 22 tests GREEN. [Story: FR-K3-DEM-086 / 101..102]

**Phase 4 exit gate** : `k3.test.sh --level 1,2` 22/22 GREEN
(20 L1 + 2 L2). `verify.sh` aggregate increases by ≈ 1 (new
standard registered). All ADRs honored.

---

## Phase 5 — Quality : docs + CHANGELOG + open-questions flip + review

### T-OQ — Open-questions flip

- [ ] **T-OQ-001** : Edit `.forge/changes/k3-demeter/open-questions.md`
      to flip Q-001 / Q-002 / Q-003 from `Status: open` to
      `Status: answered` ; add `### Resolution` blocks citing
      ADR-K3-002 / ADR-K3-003 / ADR-K3-005 verbatim, per the
      J.8 precedent. [Story: Article III.4 / FR-K3-DEM-008]

### T-DOC — Documentation

- [ ] **T-DOC-001** [P] : Add a new H2 section
      "Demeter — Data Steward EU" to `docs/AGENTS.md` (or the
      agent-catalogue doc located at impl time) summarising
      persona + 3 responsibilities + invocation surfaces +
      cross-link to the new standard. [Story: FR-K3-DEM-110]
- [ ] **T-DOC-002** [P] : Add `## [Unreleased]` entry in
      `CHANGELOG.md` covering the 3 sub-modules (K.3.a persona +
      K.3.b scanner + K.3.c standards integration).
      [Story: FR-K3-DEM-111]
- [ ] **T-DOC-003** [P] : Optional — extend
      `docs/COMPLIANCE.md` (if present) with a Demeter-aware
      paragraph, OR mark as "deferred to I.6" if the file does
      not exist at impl time. [Story: FR-K3-DEM-110]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Run `/forge:review k3-demeter` driving the
      constitutional gate review : Articles I (TDD), III + III.4,
      IV (delta), V (audit trail), VIII (CI), IX (security
      /observability), XI (AI-First), XII (governance). Block if
      any returns VIOLATION. [Story: Article V]
- [ ] **T-REV-002** : Run the full `verify.sh` once more on a
      clean checkout to confirm reproducibility.
      [Story: NFR-K3-DEM-002]
- [ ] **T-REV-003** : Verify
      `bin/forge-questions.sh --change k3-demeter --status open`
      returns empty (Q-001..Q-003 all answered post-design + flip).
      [Story: Article III.4]
- [ ] **T-REV-004** : Smoke test 3 BDD scenarios from `specs.md`
      manually :
      - Synthetic T2 tree with US-jurisdiction Cargo.lock entry
        → scanner exits 3 + `K3-RULE-001` High finding.
      - Synthetic T1 tree with Zitadel-cloud config but no
        `.forge-dpa-declared` → scanner emits `K3-RULE-002` High
        finding.
      - Synthetic T3 clean tree → scanner exits 0,
        `overall_status: "CLEARED"`, byte-identical re-run with
        `SOURCE_DATE_EPOCH=0`.
      [Story: Article II / FR-K3-DEM-068 / 121 / NFR-K3-DEM-005]
- [ ] **T-REV-005** : Confirm Janus dispatch flow via
      `cross-layer-orchestrator.md` Step 9 narrative reads
      cleanly with the appended Demeter paragraph. Manual
      reviewer pass. [Story: FR-K3-DEM-081 / ADR-K3-007]

**Phase 5 exit gate (= change archival readiness)** :

- `k3.test.sh --level 1,2` ≥ 22 PASS / 0 FAIL / ≤ 20 s.
- `verify.sh` aggregate ≥ baseline + 1 PASS / 0 FAIL / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `j8.test.sh` 20/20 PASS unchanged.
- `j7.test.sh` 21/21 PASS unchanged.
- `t5-otel.test.sh` 14/14 PASS unchanged.
- `validate-standards-yaml.sh` exits 0 on the live tree (the
  new `data-stewardship-rules.md` is MD not YAML, so J.7
  doesn't gate ; the new
  `.forge/data/cloud-act-publishers.yml` is data not standard,
  outside J.7 scope).
- `bin/forge-questions.sh --change k3-demeter --status open`
  empty.
- 3 BDD scenarios manually smoked.
- All FR-K3-DEM-001..124 + NFR-K3-DEM-001..009 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/AGENTS.md` (or equivalent) Demeter section added.

---

## Constitutional task review (per Article V)

| Task family | TDD order                                     | Spec link                                  | Architecture                                        |
|-------------|-----------------------------------------------|--------------------------------------------|-----------------------------------------------------|
| T-PHA-*     | RED phase (intentional)                       | FR-K3-DEM-100..102                         | N/A                                                 |
| T-DAT-*     | Skeleton then seed                            | FR-K3-DEM-064 / NFR-K3-DEM-008             | ADR-K3-003                                          |
| T-PER-*     | RED witness then persona skeleton             | FR-K3-DEM-001..003 / 010                   | ADR-K3-001                                          |
| T-CHK-*     | RED witness then checklist sub-sections       | FR-K3-DEM-004 / 020..074                   | Aegis pattern                                       |
| T-OUT-*     | RED witness then output H2                    | FR-K3-DEM-005 / 071..072                   | Aegis output template                               |
| T-CAT-*     | RED witness then rule table                   | FR-K3-DEM-006 / 120..124                   | ADR-K3-005                                          |
| T-INT-*     | RED witness then integration + anti-halluc    | FR-K3-DEM-007..008 / 011 / 112             | ADR-K3-007                                          |
| T-PUB-*     | RED witness then YAML seed entries            | FR-K3-DEM-064..067 / 123                   | ADR-K3-003 / 006                                    |
| T-SCN-*     | RED witness then bash thin                    | FR-K3-DEM-060..062 / 021..026              | ADR-K3-004                                          |
| T-PYE-*     | Phase-by-phase Python engine                  | FR-K3-DEM-040..044 / 060..074 / 121        | ADR-K3-002 / 004 / 006                              |
| T-L2-*      | RED witness then fixture impl                 | FR-K3-DEM-102 / NFR-K3-DEM-005             | Eris fixture convention                             |
| T-STD-*     | RED witness then standard MD                  | FR-K3-DEM-083                              | global/standards-lifecycle.md + ADR-K3-002 / 003 / 005 |
| T-IDX-*     | RED witness then index entry                  | FR-K3-DEM-082                              | global/standards-lifecycle.md                       |
| T-JAN-*     | RED witness then Janus delta-edit             | FR-K3-DEM-080..081                         | ADR-K3-007 + Article IV.1                           |
| T-CLM-*     | RED witness then CLAUDE.md row                | FR-K3-DEM-084                              | Forge agent dispatch convention                     |
| T-NSC-*     | RED witness then verify (no edit needed)      | FR-K3-DEM-086 / ADR-K3-005                 | ADR-J8-004 inheritance                              |
| T-OQ-*      | Open-questions flip                           | Article III.4                              | J.8 precedent                                       |
| T-DOC-*     | No code, doc-only                             | FR-K3-DEM-110..112                         | AGENTS + CHANGELOG conventions                      |
| T-REV-*     | Final gate, no production code                | Article V / II (BDD smoke)                 | All articles                                        |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 6     | 2                    | 22 stubs      |
| 2     | 16    | 1                    | 9 (per cluster) |
| 3     | 18    | 4                    | 7 (per cluster) |
| 4     | 14    | 2                    | 5 (per cluster) |
| 5     | 9     | 3                    | 0 (validation only) |
| **Total** | **63** | **12** | **43 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1 h,
Phase 2 ≈ 4–5 h, Phase 3 ≈ 5–6 h, Phase 4 ≈ 3–4 h, Phase 5
≈ 1 h. Total ≈ 2–2.5 working days, consistent with the **M**
complexity estimate in `proposal.md` (`new-archetypes-plan` §1.4
row K.3 effort = `M`).
