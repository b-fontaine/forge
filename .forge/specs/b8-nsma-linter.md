# Spec: b8-nsma-linter

<!-- Audit: B.8.11 (b8-11-nsma-linter) -->
<!-- Source change : `.forge/changes/b8-11-nsma-linter/` (delta specs.md authoritative). -->

**Namespace** : `FR-B811-*` / `NFR-B811-*` / `ADR-B811-*`.
**Constitution** : v1.1.0, unchanged (no amendment — Q-001 adjudicated by independent
reviewer 2026-06-03 → ADR-B811-001: NO fresh Article XII amendment required). Article VI.3
("State management SHALL use `flutter_bloc` exclusively … No other … permitted without
explicit constitutional amendment") is **ENFORCED** by this change — not violated. The
amendment clause guards *loosening*, not *enforcing*; ADR-006 already ratifies the blocking
CI gate; `activation_planned: "B.8 (T6)"` was a scheduled deferral — B.8.11 is the planned
activation of a ratified-blocking rule.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-Hallucination — rule
already exists, data flip only), IV (delta-based: ADDED FRs only — no prior `.forge/specs/`
file owns state-management enforcement), V (harness + gates before flip; full ~50-harness
suite before push; POST-flip re-run), VI.3 (flutter_bloc SHALL — the article being
activated), XII (F.4 §1 adjudication reserved for reviewer — resolved: no amendment needed).

No `.forge/specs/` file previously owned state-management enforcement.
All requirements below are therefore **ADDED** (Article IV delta-based).

## Overview

B.8.11 delivers the **NSMA linter activation**: a pure DATA flip in
`.forge/standards/state-management.yaml` (`enforcement.ci_blocking: false → true`) that
activates the no-state-management-alternatives rule already implemented at
`constitution-linter.sh:665-731`. No new bash is written; the linter already branches
FAIL vs WARN keyed entirely on the `ci_blocking:` flag (L715-719). The change also:

- Bumps `state-management.yaml` v1.0.0 → v1.1.0 (additive minor — enforcement activation,
  no `forbidden:`/`flutter:` change, structural-exception pair intact).
- Replaces `activation_planned: "B.8 (T6)"` with `activated_by: b8-11-nsma-linter` audit
  trail field.
- Appends the NSMA section + `FORGE_LINTER_SKIP_NSMA` opt-out row to
  `global/linting-rules.md`.
- Ships `b8-11.test.sh` (16 L1 + 2 L2) and registers it in `forge-ci.yml`.
- Independent reviewer adjudicated Q-001 (no fresh amendment) and issued a final APPROVE.
- Archived 2026-06-03.

## GROUND-TRUTH FINDINGS (Article III.4)

**Ground truth (re-read 2026-06-03):**

- **The rule already exists and runs — no new bash needed.**
  `constitution-linter.sh:665-731` (observed) parses the `forbidden:` list,
  reads `enforcement.ci_blocking` from `state-management.yaml`, and branches
  FAIL vs WARN at L715-719 keyed entirely on the `ci_blocking:` flag:
  ```bash
  # L715-719 (quoted verbatim from constitution-linter.sh):
  if [ "$nsma_blocking" = "1" ]; then
    fail "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, ci_blocking=true)"
  else
    warn "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, warn-only ; ci_blocking flips at B.8/T6)"
  fi
  ```
  B.8.11 is a **data flip** in `state-management.yaml`, not a code change.
- **The flip enforces an EXISTING constitutional SHALL.** Article VI.3 +
  ADR-006 + the ARCHITECTURE-TARGET.md `state-management.yaml` spec block
  already prescribe `ci_blocking: true`. The WARN-only state was an
  explicitly-temporary `activation_planned: "B.8 (T6)"` deferral. B.8.11
  is the planned activation of a ratified-blocking rule.
- **Q-001 (F.4 §1 amendment tension) — RESOLVED by independent reviewer 2026-06-03.**
  **Ruling (a): NO fresh Article XII amendment required.** Article VI.3 already mandates
  flutter_bloc exclusively (the amendment clause guards *loosening*, not *enforcing*);
  ADR-006 ratifies the blocking CI gate; `activation_planned: "B.8 (T6)"` was a scheduled
  deferral. F.4 §1's amendment precondition is satisfied by the pre-existing VI.3+ADR-006
  ratification; B.8.11 supplies §2-4.
- **Backward-compat (F.4 §3) holds by construction.** The NSMA `find` excludes
  `/.forge/` + `/examples/` + `/.dart_tool/`. Template `.tmpl` files under `.forge/` are
  never scanned. The live tree stays GREEN post-flip — verified at implement; captured in
  harness. Zero scannable forbidden dep exists in the live tree.
- **No pre-commit runner ships.** Only hook spec is G.2's commit-msg scope hook
  (`git-workflow.md` — different concern, not dep linting). Flipping `pre_commit_hook: true`
  would be a flag without a runner → a hallucinated gate. Q-002 → ADR-B811-002: keep
  `pre_commit_hook: false`.
- **J.7 validator coupling.** `bin/validate-standards-yaml.sh` FR-J7-023: bumped `version`
  MUST appear in a REVIEW.md table row. Bumping `state-management.yaml` forces a REVIEW.md
  row. The structural-exception pair (`expires_at: never` ⇔ `exception_constitutional: true`,
  FR-J7-020 bidirectional) MUST stay intact.
- **I.3 interlock preserved.** The I.3 generic forbidden walk hard-excludes
  `state-management.yaml` (`EXCLUDE_STANDARDS`, NFR-I3-T3F-001) so NSMA and T3-Forbidden
  never double-fire. B.8.11 MUST NOT disturb that exclusion.

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4.2 B.8.11 — "Linter no-state-management-alternatives (Hera)" |
| **NSMA linter section (observed)** | `constitution-linter.sh:665-731` — reads `state-management.yaml::enforcement.ci_blocking`; branches fail/warn at L715-719 on the flag value |
| **WARN branch (observed, L718-719)** | `warn "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, warn-only ; ci_blocking flips at B.8/T6)"` |
| **FAIL branch (observed, L715-717)** | `fail "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, ci_blocking=true)"` |
| **state-management.yaml (live, observed)** | `.forge/standards/state-management.yaml` — `version: "1.0.0"`, `ci_blocking: false`, `pre_commit_hook: false`, `activation_planned: "B.8 (T6)"`, 8 forbidden pkgs, `expires_at: never`, `exception_constitutional: true` |
| **Forbidden pkg list (observed, 8 entries)** | `flutter_riverpod`, `riverpod`, `provider`, `get`, `getx`, `mobx`, `flutter_mobx`, `states_rebuilder` |
| **F.4 §1 add-a-rule protocol (observed)** | `global/linting-rules.md:L173-190` — tightening requires: (1) Constitution amendment, (2) F.x change, (3) backward-compat audit, (4) update of this standard |
| **F.4 opt-out matrix (observed)** | `global/linting-rules.md:L160-166` — table of `FORGE_LINTER_SKIP_*` env vars per rule |
| **REVIEW.md row format (observed)** | `REVIEW.md:2026-05-05` b8-7 identity.yaml v1.1.0 row — `| identity.yaml | 1.1.0 | KEEP-WITH-CHANGES | ... |` with `Next review due: never (structural)` |
| **J.7 FR-J7-023 coupling** | `bin/validate-standards-yaml.sh` — bumped `version` MUST appear as a REVIEW.md table row; validator exit 0 required |
| **I.3 interlock** | `constitution-linter.sh:732+` ADR-I3-001 section; `FORGE_LINTER_SKIP_NSMA=1` in `_run_linter_in_fixture` of `i3.test.sh` confirms NSMA is separate from T3-Forbidden |
| **Harness pattern (observed)** | `.forge/scripts/tests/i3.test.sh` — `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`, L1 hermetic, L2 `FORGE_LINTER_FIXTURE_ROOT` fixture |
| **Dependencies** | T.4 (state-management.yaml v1.0.0), F.4 (linting-rules.md governance), I.3 (NSMA section + interlock) |
| **Release target** | v0.4.0-rc.13 |

---

## ADDED Requirements

### Functional Requirements

#### Group 1 — Standard enforcement flip (FR-B811-001 → 006)

##### FR-B811-001 — `state-management.yaml` `ci_blocking` flipped to `true`
`state-management.yaml` `enforcement.ci_blocking` MUST be `true` after this
change. The grep-testable sentinel is:
`grep -E '^[[:space:]]+ci_blocking:[[:space:]]+true' .forge/standards/state-management.yaml`
must exit 0. The prior value `false` MUST NOT remain. Testable: grep for
`ci_blocking: false` → zero matches; grep for `ci_blocking: true` → one match.

##### FR-B811-002 — `activation_planned` resolved with audit-trail field/comment
The `activation_planned: "B.8 (T6)"` line in `state-management.yaml` MUST
be resolved. Per ADR-B811-004: it MUST be replaced with an
`activated_by: b8-11-nsma-linter` field recording that B.8.11 performed the
activation, rather than silently deleted. The invariant: `grep "activation_planned"
.forge/standards/state-management.yaml` MUST exit non-zero (the original marker is
gone) AND an audit trail mentioning `b8-11` or `B.8.11` MUST be present in the same
block. Testable: grep for `activation_planned` → zero matches; grep for
`b8-11\|B.8.11` near the enforcement block → at least one match.

##### FR-B811-003 — `forbidden:` / `flutter:` / `linter_rule:` blocks BYTE-UNCHANGED
The `forbidden:` list (8 packages: `flutter_riverpod`, `riverpod`, `provider`,
`get`, `getx`, `mobx`, `flutter_mobx`, `states_rebuilder`), the `flutter:`
block (`standard: flutter_bloc`, `version_pinned: ^9.0.0`, `companions:
[bloc_test, hydrated_bloc, replay_bloc]`), and the `linter_rule:
no-state-management-alternatives` line MUST be byte-unchanged after the flip.
B.8.11 only flips enforcement; no forbidden-pkg or flutter-pin change is in
scope. Testable: `git diff .forge/standards/state-management.yaml` MUST show
no changes to `forbidden:` entries, `flutter:` block, or `linter_rule:` line.

##### FR-B811-004 — Structural-exception pair (`expires_at: never` ⇔ `exception_constitutional: true`) intact
The structural-exception pair MUST survive the version bump unchanged:
`expires_at: never` AND `exception_constitutional: true` MUST both be present
in `state-management.yaml` after the edit. FR-J7-020 bidirectional guard:
these two fields must co-exist (neither may be present without the other).
Testable: `grep "expires_at: never" .forge/standards/state-management.yaml`
→ exit 0; `grep "exception_constitutional: true"` → exit 0.

##### FR-B811-005 — `pre_commit_hook` value invariant: no flag set `true` without a shipped runner
The `pre_commit_hook:` field MUST NOT be set to `true` unless a shipped
pre-commit runner artifact exists in the repo. Per ADR-B811-002 (keep `false`
— no runner ships; runner is G.2 territory), the field MUST remain `false`.
Testable: `grep "pre_commit_hook: true" .forge/standards/state-management.yaml`
→ zero matches.

##### FR-B811-006 — `last_reviewed` date updated in `state-management.yaml`
`state-management.yaml::last_reviewed` MUST be updated to the implementation
date (2026-06-03 or later). The stale `2026-05-04` value from the T.4 birth
MUST NOT remain after the bump. Testable: `grep "last_reviewed: 2026-05-04"
.forge/standards/state-management.yaml` → zero matches; `grep "last_reviewed:"
.forge/standards/state-management.yaml` → one match with a later date.

---

#### Group 2 — Version bump + REVIEW.md (FR-B811-010 → 013)

##### FR-B811-010 — `state-management.yaml` version bumped to `1.1.0`
`state-management.yaml::version` MUST be `"1.1.0"` after the change (from
`"1.0.0"`). The bump magnitude is additive minor (ADR-B811-003):
enforcement activation with no `forbidden:`/`flutter:` change and no breaking
structural-exception mutation. Testable: `grep 'version: "1.1.0"'
.forge/standards/state-management.yaml` → exit 0; `grep 'version: "1.0.0"'`
→ zero matches.

##### FR-B811-011 — In-file version-history comment in `state-management.yaml`
`state-management.yaml` MUST carry an in-file version-history comment block
recording the 1.0.0 → 1.1.0 bump (mirroring the b8-7 identity.yaml style).
The comment MUST mention `b8-11-nsma-linter` as the change that performed the
bump and briefly describe what changed (ci_blocking activation). Testable:
`grep "b8-11-nsma-linter" .forge/standards/state-management.yaml` → exit 0.

##### FR-B811-012 — REVIEW.md `Updated`/`KEEP-WITH-CHANGES` row for version `1.1.0`
`REVIEW.md` MUST have a new append-only H2 entry (format per the REVIEW.md
schema at the top of the file) recording the `state-management.yaml`
`1.1.0` bump. The row in the standards table MUST carry:
- Standard: `state-management.yaml`
- Version: `1.1.0`
- Decision: `KEEP-WITH-CHANGES`
- Next review due: `never (structural)` (structural exception preserved)
- Notes: brief activation description citing `b8-11-nsma-linter`

This satisfies FR-J7-023 (version⇔REVIEW coupling). Testable:
`grep "state-management.yaml" .forge/standards/REVIEW.md` → at least one
match; `grep "1.1.0" .forge/standards/REVIEW.md` → at least one match;
`grep "b8-11-nsma-linter" .forge/standards/REVIEW.md` → exit 0.

##### FR-B811-013 — `bin/validate-standards-yaml.sh` exits 0 post-change
After all Group 1 + Group 2 edits are applied,
`bash .forge/scripts/validate-change-yaml.sh` (or the equivalent standards
validator) MUST exit 0. This verifies: (a) version `1.1.0` matches the
REVIEW.md row (FR-J7-023); (b) structural-exception pair intact (FR-J7-020);
(c) no schema violations.

---

#### Group 3 — Governance doc (`linting-rules.md`, F.4 §4) (FR-B811-020 → 023)

##### FR-B811-020 — NSMA rule section appended to `linting-rules.md`
`global/linting-rules.md` MUST have a new H2 section documenting the NSMA rule
(`no-state-management-alternatives`). The section MUST include at minimum:
(a) the rule name and the linter section anchor (`ADR-006 State Management
Discipline — no-state-management-alternatives`); (b) description of the
warn→fail activation performed by B.8.11; (c) the constitutional basis
(Article VI.3 + ADR-006); (d) what triggers the rule (forbidden pkg in
`pubspec.yaml`); (e) what the violation message looks like (quoting the FAIL
branch from `constitution-linter.sh:L716`). Testable: `grep -F
"no-state-management-alternatives" .forge/standards/global/linting-rules.md`
→ exit 0; `grep "ADR-006" .forge/standards/global/linting-rules.md` → exit 0.

##### FR-B811-021 — `FORGE_LINTER_SKIP_NSMA` opt-out row added to the opt-out matrix
The opt-out matrix table in `linting-rules.md` (observed at L160-166) MUST
have a new row for `FORGE_LINTER_SKIP_NSMA`:

| Env var | Effect |
| `FORGE_LINTER_SKIP_NSMA=1` | Skip ADR-006 state management alternatives check |

Testable: `grep "FORGE_LINTER_SKIP_NSMA" .forge/standards/global/linting-rules.md`
→ exit 0.

##### FR-B811-022 — Backward-compat note recorded in the NSMA section
The NSMA section in `linting-rules.md` MUST record the backward-compat note:
the NSMA scan excludes `/.forge/`, `/examples/`, and `/.dart_tool/` so
template `.tmpl` files and archived examples are never retroactively failed.
This is the F.4 §3 backward-compat audit result. Testable: `grep -E
"\.forge/|backward[- ]compat" .forge/standards/global/linting-rules.md` →
exit 0 in the NSMA section context.

##### FR-B811-023 — ADR-006 and VI.3 cited in the NSMA section
The NSMA section in `linting-rules.md` MUST cite both `ADR-006` and
`Article VI.3` (or `VI.3`) explicitly, establishing the constitutional
basis for the rule. This satisfies the F.4 §4 "update this standard"
requirement with correct provenance. Testable: `grep "ADR-006"` AND
`grep "VI.3"` in `linting-rules.md` within the NSMA section → both exit 0.

---

#### Group 4 — Backward-compat audit (F.4 §3) (FR-B811-030 → 032)

##### FR-B811-030 — Live-tree linter OVERALL PASS preserved post-flip
After `state-management.yaml` `ci_blocking` is set to `true`, running
`bash .forge/scripts/constitution-linter.sh` against the Forge repo root MUST
still exit with an OVERALL PASS. No scannable `pubspec.yaml` in the live tree
(excluding `/.forge/` + `/examples/` + `/.dart_tool/`) may contain any of the
8 forbidden packages. Testable: after the flip,
`bash .forge/scripts/constitution-linter.sh 2>&1 | grep "OVERALL.*PASS"` → exit 0.

##### FR-B811-031 — No archived change FAILs retroactively
Archived changes under `.forge/changes/` that are stored as inactive artifacts
MUST NOT cause the NSMA rule to emit FAIL retroactively. The NSMA scan
excludes `/.forge/` (line `grep -v "/.forge/"` observed at
`constitution-linter.sh:702`), so archived `.forge/changes/**` subtrees are
never scanned. B.8.11 MUST NOT remove or weaken that exclusion.

##### FR-B811-032 — Backward-compat assertion captured in harness + evidence note
The harness `b8-11.test.sh` MUST include an assertion (L1 hermetic) that:
(a) the live-tree NSMA section with `ci_blocking: true` does NOT emit a FAIL
line when run against the real Forge root (confirming no scannable forbidden
dep exists); OR (b) a clean-tree assertion that no pubspec.yaml outside
`/.forge/` and `/examples/` contains a forbidden pkg. The evidence note MUST
record when the backward-compat check was performed.

---

#### Group 5 — Enforcement behavior (the activated rule) (FR-B811-040 → 043)

##### FR-B811-040 — Forbidden-dep pubspec makes NSMA section emit FAIL (exit 1)
Post-flip, when `constitution-linter.sh` scans a `pubspec.yaml` that declares
any of the 8 forbidden packages (e.g., `riverpod: ^2.0.0`), the NSMA section
(ADR-006 State Management Discipline) MUST emit a `FAIL` line (not `WARN`).
The FAIL message MUST match:
`forbidden state-mgmt dep '${pkg}' in <path> (no-state-management-alternatives, ci_blocking=true)`
(verbatim from `constitution-linter.sh:L716`). The overall linter MUST exit
non-zero. Testable via the L2 harness fixture (FR-B811-062).

##### FR-B811-041 — Clean `flutter_bloc`-only pubspec passes NSMA section
A `pubspec.yaml` declaring only `flutter_bloc` (no forbidden package) MUST
cause the NSMA section to emit a PASS line:
`no forbidden state-mgmt deps detected across N pubspec.yaml file(s)`
(verbatim from `constitution-linter.sh:L725`). Testable via the L2 harness
fixture (FR-B811-063).

##### FR-B811-042 — I.3 interlock (state-management.yaml excluded from T3 walk) MUST remain
The I.3 generic T3-Forbidden walk excludes `state-management.yaml` from its
YAML-standard discovery scan (`EXCLUDE_STANDARDS`, NFR-I3-T3F-001). B.8.11
MUST NOT remove or weaken this exclusion. Testable: the NSMA section runs
exactly once (not under T3-Forbidden). Cross-check: `grep
"EXCLUDE_STANDARDS\|state-management" .forge/scripts/constitution-linter.sh`
→ the exclusion comment/variable must still be present unchanged.

##### FR-B811-043 — NO new bash added to `constitution-linter.sh` (data flip only)
B.8.11 MUST NOT add any new bash scan logic, new section, or new function to
`constitution-linter.sh`. The only permissible changes to `constitution-linter.sh`
are comment-only edits, or no change at all. Testable:
`git diff .forge/scripts/constitution-linter.sh | grep "^+" | grep -v "^+++"
| grep -v "^+[[:space:]]*#"` → zero matches (no non-comment additions).

---

#### Group 6 — Harness + CI + CHANGELOG (FR-B811-050 → 057)

##### FR-B811-050 — Harness file created at `.forge/scripts/tests/b8-11.test.sh`
The brick MUST create `.forge/scripts/tests/b8-11.test.sh`. The file MUST be
present and executable. It MUST open with:
```
#!/usr/bin/env bash
# Forge — B.8.11 NSMA linter activation test harness (b8-11-nsma-linter)
# <!-- Audit: B.8.11 (b8-11-nsma-linter) -->
```
Testable: `[ -f .forge/scripts/tests/b8-11.test.sh ] && [ -x
.forge/scripts/tests/b8-11.test.sh ]` → exit 0; `grep "Audit: B.8.11
(b8-11-nsma-linter)" .forge/scripts/tests/b8-11.test.sh` → exit 0.

##### FR-B811-051 — Harness structure: `--level` flag, `source _helpers.sh`, `run_test`/`print_summary`
`b8-11.test.sh` MUST implement the standard harness pattern (mirroring
`i3.test.sh`): `--level` flag parsed at the top; `source "$HARNESS_DIR/_helpers.sh"`;
`PASS=0; FAIL=0; FAIL_NAMES=()` counters; each test in a named function;
`run_test <fn>` and `print_summary` in `main()`. Testable: `grep "source.*_helpers.sh"
.forge/scripts/tests/b8-11.test.sh` → exit 0; `grep "print_summary"` → exit 0.

##### FR-B811-052 — L1 hermetic assertions (16 tests, ≤ 2 s wall-clock)
**Delivered: 16 L1 tests, all GREEN.** The L1 block asserts all of the following
(each as a named test function):
1. `state-management.yaml` `ci_blocking: true` present (FR-B811-001).
2. `state-management.yaml` `version: "1.1.0"` present (FR-B811-010).
3. `state-management.yaml` `activation_planned` absent (FR-B811-002).
4. `state-management.yaml` `b8-11` audit trail present (FR-B811-002).
5. `state-management.yaml` structural-exception pair intact (`expires_at: never`
   + `exception_constitutional: true`) (FR-B811-004).
6. `state-management.yaml` `pre_commit_hook: false` (FR-B811-005).
7. REVIEW.md contains `state-management.yaml` + `1.1.0` + `b8-11-nsma-linter` (FR-B811-012).
8. `linting-rules.md` contains `no-state-management-alternatives` section (FR-B811-020).
9. `linting-rules.md` contains `FORGE_LINTER_SKIP_NSMA` opt-out row (FR-B811-021).
10. CHANGELOG.md contains `b8-11-nsma-linter` anchor (FR-B811-056).
11. forge-ci.yml contains `b8-11.test.sh` entry (FR-B811-055).
12. `constitution-linter.sh` has no non-comment additions (FR-B811-043).
13–14. b8-3 and i3 coupling guard exit-codes (FR-B811-053).
15. Live-tree backward-compat: no forbidden dep in live tree (FR-B811-057).
16. `b8-11.test.sh` script itself exists and is executable (FR-B811-050).

All L1 tests complete in ≤ 2 s wall-clock (grep/stat only).

##### FR-B811-053 — Coupling guards: b8-3 and i3 exit-code assertions
`b8-11.test.sh` MUST include exit-code coupling guards:
- `.forge/scripts/tests/b8-3.test.sh --level 1` → must exit 0 (schema
  invariants GREEN; verifies validate-standards-yaml still passes after the
  state-management.yaml bump — satisfies FR-B811-013).
- `.forge/scripts/tests/i3.test.sh --level 1` → must exit 0 (I.3 interlock
  intact; verifies NSMA exclusion not disturbed — satisfies FR-B811-042).
A non-zero exit from either coupling guard is a b8-11 FAIL.

##### FR-B811-054 — L2 fixture block (opt-in, gated on `FORGE_LINTER_FIXTURE_ROOT`)
**Delivered: 2 L2 tests.** `b8-11.test.sh` includes an L2 block gated on
`FORGE_LINTER_FIXTURE_ROOT` being set by the caller (mirroring the pattern
from `i3.test.sh`). When the env var is set to a tmpdir containing a synthetic
fixture, L2 runs:
- `_test_b811_l2_forbidden_pubspec`: creates a pubspec.yaml with `riverpod:
  ^2.0.0` in the fixture root, invokes `constitution-linter.sh` with
  `FORGE_LINTER_FIXTURE_ROOT=<tmpdir>`, asserts the NSMA section emits a FAIL
  line containing `riverpod` and `ci_blocking=true` (FR-B811-040).
- `_test_b811_l2_clean_pubspec`: creates a pubspec.yaml with only `flutter_bloc:
  ^9.0.0`, asserts the NSMA section emits a PASS line (FR-B811-041).
When `FORGE_LINTER_FIXTURE_ROOT` is unset, L2 emits a skip-pass and contributes
0 failures.

##### FR-B811-055 — forge-ci.yml registration
`b8-11.test.sh` MUST be registered in `.github/workflows/forge-ci.yml` as a
one-line entry `"b8-11.test.sh --level 1"` placed after the `b8-10.test.sh`
line. Testable: `grep "b8-11.test.sh" .github/workflows/forge-ci.yml` → exit 0.

##### FR-B811-056 — CHANGELOG entry anchored `b8-11-nsma-linter`
`CHANGELOG.md` `[Unreleased]` section MUST have an entry for this change.
The entry MUST contain the string `b8-11-nsma-linter` (whole-file grep).
Testable: `grep "b8-11-nsma-linter" CHANGELOG.md` → exit 0.

##### FR-B811-057 — Live-tree backward-compat assertion in harness
`b8-11.test.sh` L1 MUST include a test that asserts no pubspec.yaml outside
`/.forge/` and `/examples/` contains a forbidden pkg (confirming no scannable
forbidden dep in the live tree). A FAIL in this test means a forbidden dep
exists in the live tree and MUST be resolved before the change can proceed.

---

### Non-Functional Requirements

##### NFR-B811-001 — L1 harness wall-clock ≤ 2 s (hermetic)
`b8-11.test.sh` L1 wall-clock MUST be ≤ 2 s on the CI runner (no Docker, no
network). All L1 assertions are grep/stat/file-exists operations.
**DELIVERED: 16 L1 tests, all GREEN, ≤ 2 s.**

##### NFR-B811-002 — Full ~50-harness suite GREEN pre-push
Before pushing, the full forge-ci harness suite (all ~50 harnesses in
`.forge/scripts/tests/`) MUST pass (`full_harness_suite_before_push` memory
lesson). This includes b8-3 (schema), i3 (T3-Forbidden / interlock), and any
harness whose repo-wide scan is affected by the `linting-rules.md` or
`state-management.yaml` edits. **DELIVERED: full suite 50/50.**

##### NFR-B811-003 — NO new scan logic in `constitution-linter.sh`
B.8.11 is a data + governance flip. `constitution-linter.sh` MUST receive
zero new functional bash lines. The only permissible mutation is a comment
update. Verified by FR-B811-043 (git diff check).

##### NFR-B811-004 — J.7 validator PASS (`bin/validate-standards-yaml.sh` exit 0)
`bin/validate-standards-yaml.sh .forge/standards/` MUST exit 0 post-change,
verifying version⇔REVIEW coupling (FR-J7-023) and structural-exception pair
(FR-J7-020). Verified by FR-B811-013 and coupling guard FR-B811-053.

##### NFR-B811-005 — Structural-exception pair preserved across the bump
`expires_at: never` AND `exception_constitutional: true` MUST co-exist in
`state-management.yaml` v1.1.0. Removing either field is a constitutional
violation. Verified by FR-B811-004 and the L1 harness assertion.

##### NFR-B811-006 — Live-tree linter OVERALL PASS preserved (backward-compat)
The Forge repo's `constitution-linter.sh` OVERALL result MUST NOT regress from
PASS to FAIL as a result of the `ci_blocking: true` flip. Verified by
FR-B811-030 and FR-B811-057. **DELIVERED: live tree OVERALL PASS confirmed.**

##### NFR-B811-007 — Independent review required before `/forge:plan` and pre-archive
These specs passed an **independent reviewer** (not the author) before
`/forge:design` proceeded (t5-2 self-validation lesson; Q-001 adjudicated by the
reviewer — not self-ruled). Independent review completed pre-archive.
**DELIVERED: independent reviewer issued final APPROVE 2026-06-03.**

##### NFR-B811-008 — I.3 interlock preserved (no double-fire)
The `state-management.yaml` exclusion from the I.3 T3-Forbidden walk MUST
remain intact. B.8.11 MUST NOT introduce any code or config change that causes
the NSMA rule to fire under the T3-Forbidden section. Verified by FR-B811-042
and the i3.test.sh coupling guard (FR-B811-053).

---

## Architecture Decision Records

| ADR | Decision | As-Implemented Resolution |
|-----|----------|--------------------------|
| **ADR-B811-001** | F.4 §1 amendment necessity (Q-001) | **RESOLVED by independent reviewer 2026-06-03 — Ruling (a): NO fresh Article XII amendment required.** Article VI.3 already mandates flutter_bloc exclusively (the amendment clause guards *loosening*, not *enforcing*); ADR-006 ratifies the blocking CI gate; `activation_planned: "B.8 (T6)"` was a scheduled deferral. F.4 §1's amendment precondition is satisfied by the pre-existing VI.3+ADR-006 ratification; B.8.11 supplies §2-4. Reviewer-ratified 2026-06-03; pre_commit_hook stays false. |
| **ADR-B811-002** | `pre_commit_hook` value (Q-002) | **RESOLVED: keep `false`.** No runner ships; runner is G.2 territory. Flipping `pre_commit_hook: true` would be a flag without a runner — a hallucinated gate. `pre_commit_hook: false` preserved. |
| **ADR-B811-003** | Version bump magnitude (Q-003) | **RESOLVED: additive minor `1.0.0 → 1.1.0`.** Enforcement activation with no `forbidden:`/`flutter:` change and no breaking structural-exception mutation. REVIEW.md `KEEP-WITH-CHANGES` row, `Next review due: never (structural)`. |
| **ADR-B811-004** | `activation_planned` resolution form (Q-004) | **RESOLVED: replace with `activated_by: b8-11-nsma-linter` field.** Provides an audit trail of the activation event rather than a silent delete. The original `activation_planned: "B.8 (T6)"` marker is gone; `activated_by:` records the performing change. |

---

## BDD Acceptance Criteria

```gherkin
Feature: NSMA linter activation — constitution-linter.sh enforces flutter_bloc exclusively
  As a Forge framework CI gate
  I want the no-state-management-alternatives rule to emit FAIL (not WARN)
  when a pubspec.yaml declares a forbidden state-management package
  So that Article VI.3 ("flutter_bloc SHALL … no other permitted") is
  machine-enforced and not merely advisory

  Scenario: Forbidden state-management dep triggers FAIL post-flip
    Given state-management.yaml has ci_blocking: true (B.8.11 applied)
    And a pubspec.yaml under FORGE_LINTER_FIXTURE_ROOT declares riverpod: ^2.0.0
    When constitution-linter.sh runs with FORGE_LINTER_FIXTURE_ROOT set
    Then the NSMA section (ADR-006 State Management Discipline) emits a FAIL line
    And the FAIL message contains "riverpod" and "ci_blocking=true"
    And the overall linter exits non-zero

  Scenario: Clean flutter_bloc-only project passes the NSMA section
    Given state-management.yaml has ci_blocking: true (B.8.11 applied)
    And a pubspec.yaml under FORGE_LINTER_FIXTURE_ROOT declares only flutter_bloc: ^9.0.0
    When constitution-linter.sh runs with FORGE_LINTER_FIXTURE_ROOT set
    Then the NSMA section emits a PASS line
    And the PASS message contains "no forbidden state-mgmt deps detected"
    And the overall linter exits 0 (assuming no other violations)

  Scenario: Forge's own live tree stays OVERALL PASS unchanged post-flip
    Given state-management.yaml has ci_blocking: true (B.8.11 applied)
    And no pubspec.yaml outside /.forge/ and /examples/ declares a forbidden package
    When constitution-linter.sh runs against the Forge repo root (no fixture override)
    Then the NSMA section emits a PASS line
    And the overall linter result is OVERALL PASS (identical to pre-flip)
    And no archived .forge/changes/ pubspec.yaml is scanned (/.forge/ excluded)
```
