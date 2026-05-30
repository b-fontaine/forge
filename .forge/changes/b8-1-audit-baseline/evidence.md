# Evidence — b8-1-audit-baseline

<!-- Article V audit trail. Captured 2026-05-30. -->

## TDD RED → GREEN

### RED (Phase 1, deliverables absent)

`bash .forge/scripts/tests/b8-1.test.sh --level 1` → **Passed: 2 / Failed: 8**.
8 target assertions failed (doc + inventory + changelog absent); 2 passed
vacuously (`l1_006` no-MTBF on empty doc; `l1_009` cross-checks live source
files which exist independently of the deliverables). Correct RED.

### GREEN (Phase 2, deliverables authored)

`bash .forge/scripts/tests/b8-1.test.sh --level 1` → **Passed: 10 / Failed: 0**,
wall-clock **0.236 s** (NFR-B8-1-001 budget 5 s — 4.7 % used), zero
network/Docker.

## MTBF guard proof (T13 / FR-B8-1-033)

Injected `Temporal MTBF: 1200h observed.` into `docs/B8-BASELINE.md`:
- `_test_b81_l1_006_no_fabricated_mtbf` → **✗ FAIL** (Failed: 1).
Restored doc:
- `_test_b81_l1_006_no_fabricated_mtbf` → **✓ PASS** (Failed: 0).
The Article III.4 negative guard fires as designed.

## L2 skip-pass (no Docker env)

`bash .forge/scripts/tests/b8-1.test.sh --level 2` → **Passed: 11 / Failed: 0**.
`_test_b81_l2_001_live_trace_superset` skip-passes and records the
gateway-boundary truncation (placeholder backend, ADR-B8-1-002).

## Scope check (NFR-B8-1-002)

`git diff --name-only` + untracked, filtered on
`.forge/(templates|standards|schemas)/` → **NONE**. No template / standard /
schema mutated. Changed surface: `forge-ci.yml`, `CHANGELOG.md`,
`.forge/baselines/`, `.forge/changes/b8-1-audit-baseline/`,
`.forge/scripts/tests/b8-1.test.sh`, `.forge/specs/b8-baseline.md`,
`docs/B8-BASELINE.md`.

## Determinism (NFR-B8-1-003)

`md5` of the span inventory is stable across reads
(`fb780edcc11687c1b53995e108058f4a`); no timestamps in the YAML.

## Regression + gates

- `a7.test.sh` → **29 / 0** (NFR-B8-1-004, forge upgrade unaffected).
- `forge-ci.yml` → **300 lines** (NFR-CI-002 ceiling preserved via ADR-B8-1-006
  3-comment compression).
- `verify.sh` → **RESULT: PASS** (Open Questions Gate PASS — Q-001/002/003
  all `answered`).
- `constitution-linter.sh` → **OVERALL PASS** (45 PASS / 0 FAIL / 5 WARN).

## Ground-truth provenance (Article III.4)

Every pin in `docs/B8-BASELINE.md` §1 was read from the live files at
authoring time:
- `docker-compose.dev.yml` → `postgres:16-alpine`, `kong:3.6-alpine`,
  `signoz/zookeeper:3.7.1`, `clickhouse/clickhouse-server:25.5.6`,
  `signoz/signoz-otel-collector:v0.144.4`, `signoz/signoz:v0.125.1`,
  `fsm-backend image: scratch` (lines 58–64).
- `infra/k8s/base/coroot-deployment.yaml` → `ghcr.io/coroot/coroot:1.20.2`.
- `infra/k8s/base/obi-daemonset.yaml` → `grafana/beyla:3.15.0`.
- Spans: `greet.rs:32` (`greeter.greet` internal), `middleware.rs:33`
  (`http.request`, `otel.kind="server"`), `tracing_interceptor.dart:34`
  (`SpanKind.client`). Only 2 backend instrument sites + 1 Flutter client
  span exist — the demo-005 doc's "4-span" prose is 3 in code.

## Independent review round 1 — CHANGES REQUIRED → fixed (2026-05-30)

A separate-context `code-reviewer` (opus) re-ran the full matrix from scratch
(no transcript trust) and confirmed: harness 10/0, L2 11/0, a7 29/0, verify
PASS, linter PASS, validate-yaml exit 0, all 8 image pins byte-match live,
scope clean, MTBF guard genuinely fires on injection. **One blocker + 3
non-blocking findings**, all fixed:

- 🟠 **blocker** — §5 phantom-span MISATTRIBUTION. The author's own
  anti-hallucination finding #4 was itself partly hallucinated: it named the
  *connectrpc handler* as the uninstrumented 4th span. The reviewer proved
  (and I independently re-confirmed) the demo-005 doc waterfall draws the
  phantom as the **Flutter `user.interaction greet` root span** (no
  `startSpan('user.interaction …')` in `frontend/lib`); the connectrpc POST
  **is** the real client span. **Fixed**: `docs/B8-BASELINE.md` §5 + span
  inventory `notes` rewritten to name the Flutter root as the phantom;
  harness `l1_007` now asserts `user.interaction greet` + `PHANTOM` instead of
  `connectrpc handler`. Meta-lesson: validates the author≠reviewer mandate
  (`b8_coroot_inversion_lessons`) — an anti-hallucination deliverable still
  hallucinated, caught only by independent review.
- 🟡 matrix omitted `fsm-signoz-telemetrystore-migrator` (compose L235).
  **Fixed**: row added.
- 🟡 `l1_002` was tautological (doc-only, no live cross-check). **Fixed**:
  now cross-checks every pin against the live compose/k8s files.
- 🟢 MTBF regex caught only number-after-token. **Fixed**: now catches both
  orders (`MTBF.{0,12}[0-9]|[0-9].{0,12}MTBF`); re-proven on both
  `MTBF: 1200h` and `1200h MTBF`, no false positive on the legit harness-ref
  mention.

Post-fix re-run: harness 10/0, L2 11/0, a7 29/0, verify PASS, linter PASS,
CI 300 lines. Awaiting reviewer re-verdict on the fixes.

## Independent review round 2 — APPROVE (2026-05-30)

The separate-context reviewer re-derived everything from live files: §5 now
correctly names the Flutter `user.interaction greet` root as the phantom
(grep confirms zero `user.interaction` instrument site); migrator row matches
compose L235; `l1_002` genuinely cross-checks live (a doc-vs-live pin
disagreement now fails); MTBF guard catches both orders, no false positive on
the legit harness self-reference (the `6` is 14 chars from `mtbf`, outside the
12-char window). Harness 10/0, L2 11/0, a7 29/0, verify PASS, linter PASS, CI
300 lines. One LOW (span-1 label vs dynamic live name) fixed in the same pass
(`name: "<http-method> <path>"` + `name_source` in the inventory; §5 item 1
shows the dynamic form). **VERDICT: APPROVE — archive-ready.**

T23 complete. The change is implemented + independently approved; the only
remaining step is `/forge:archive` (after the release-line decision).
