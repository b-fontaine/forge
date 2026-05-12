# Specifications: t5-otel-live-run
<!-- Status: specified -->
<!-- Schema: full-stack-monorepo -->

**Namespace** : `FR-T5-OLR-*` / `NFR-T5-OLR-*` (distinct from Phase A
`FR-OTEL-*`, Phase B `FR-T5-OTA-*`, Phase C `FR-T5-TPE-*`).
**Constitution** : v1.1.0. No amendment required.

## Source Documents

| Field            | Value                                                                            |
|------------------|----------------------------------------------------------------------------------|
| **ADR base (A)** | `t5-otel-stack` (FR-OTEL-001..082 + ADR-OTEL-001..007 — collector contract)      |
| **ADR base (B)** | `t5-otel-app` (FR-T5-OTA-001..103 + ADR-T5-OTA-001..007 — SDK init)              |
| **ADR base (C)** | `t5-otel-traceparent-e2e` (FR-T5-TPE-001..091 + ADR-T5-TPE-001..006 — BDD)       |
| **Plan ref**     | `docs/new-archetypes-plan.md` line 167 — "traceparent W3C E2E validation"        |
| **Standard ref** | `.forge/standards/observability.yaml` v1.1.0 — collector contract                |
| **Standard ref** | `.forge/standards/infra/docker-compose.md` — fsm- prefix + healthchecks          |

No new external standard pinned. No standard version bump.

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Fake-collector executable (FR-T5-OLR-001..010)

##### FR-T5-OLR-001 — Fake collector file exists

`examples/forge-fsm-example/test/live-run/fake_otlp_collector.py` MUST
exist as a Python 3 script using stdlib only (no `import protobuf`,
no `import grpc`, no third-party imports). Header comment carries the
audit anchor `<!-- Audit: T.5 (t5-otel-live-run) — Phase D fake OTLP
collector -->`.

##### FR-T5-OLR-002 — Binds OTLP HTTP/protobuf port

The fake collector MUST bind `127.0.0.1:4318` by default and accept
the bind address via `--bind HOST:PORT`. It MUST handle POSTs to
`/v1/traces`, `/v1/metrics`, `/v1/logs` returning HTTP 200 + an
empty `application/x-protobuf` body. Other paths return 404.

##### FR-T5-OLR-003 — Stdlib-only protobuf tag walk

The collector MUST decode incoming POST bodies sufficiently to
extract :
1. The first `resource.attributes` entry whose key is `service.name`
   (string value).
2. The `traceparent` request header, if present.
3. A count of the embedded `ResourceSpans` records.

No `protobuf` pip dep. The implementation walks the wire format by
varint + length-delimited tag scanning per
[OTLP protobuf wire format](https://protobuf.dev/programming-guides/encoding/).

##### FR-T5-OLR-004 — Sanitisation rules

Every capture written by the collector MUST sanitise :
- Replace absolute timestamps with the literal `"<ts:redacted>"`.
- Replace any field matching `/(\d{1,3}\.){3}\d{1,3}/` (IPv4) with
  `"<ip:redacted>"`.
- Replace `host.name` resource attribute value with `"<host:redacted>"`.

This makes captures **byte-deterministic** across hosts (golden-file
comparability) and removes PII.

##### FR-T5-OLR-005 — Capture output path

The collector MUST persist each sanitised request as a JSON file under
the directory passed via `--out DIR`. Filenames are sequential
`capture-NNN.json` where NNN is zero-padded to 3 digits.

##### FR-T5-OLR-006 — JSON capture schema

Each capture JSON MUST carry exactly these top-level keys :
- `service_name` (string, may be empty if absent in payload)
- `traceparent` (string, may be empty)
- `resource_spans_count` (integer)
- `path` (string — request path)
- `method` (string — request method, must be `POST` for trace
  exports)
- `body_size_bytes` (integer)
- `timestamp` (literal `"<ts:redacted>"`)

No nested objects. Flat schema for grep-friendliness and golden-file
byte equality.

##### FR-T5-OLR-007 — Health endpoint

The collector MUST expose `GET /` returning HTTP 200 + the body
`fake-otlp-collector\n`. The smoke driver uses this for readiness
polling.

##### FR-T5-OLR-008 — Graceful shutdown

The collector MUST trap `SIGTERM` and `SIGINT`, drain pending writes,
and exit cleanly with exit 0. Pending writes drain in ≤ 1 s.

##### FR-T5-OLR-009 — Idempotent reruns

Two consecutive invocations of the smoke driver against the same
`--out` directory MUST produce identical JSON content for matching
request indices (deterministic ordering, deterministic sanitisation).
Verifiable by `diff -q capture-000.json golden.json`.

##### FR-T5-OLR-010 — No external dependencies

`python3 -c "import sys; assert sys.version_info >= (3, 8)"` is the
only environmental precondition. No `pip install`. No `venv`. The
script's shebang is `#!/usr/bin/env python3`.

---

#### Cluster 2 — Smoke driver (FR-T5-OLR-020..028)

##### FR-T5-OLR-020 — Driver script exists

`examples/forge-fsm-example/test/live-run/run_smoke.sh` MUST exist
as a bash 4+ compatible script with `set -uo pipefail`. Header
comment carries the audit anchor `<!-- Audit: T.5 (t5-otel-live-run)
— Phase D smoke driver -->`.

##### FR-T5-OLR-021 — Driver starts fake collector

The driver MUST start the fake collector in the background, wait for
readiness via `curl -fsS http://127.0.0.1:4318/` polling (timeout 5 s,
retry every 100 ms), and trap EXIT to kill the collector process. No
zombie processes after a clean exit OR a failure exit.

##### FR-T5-OLR-022 — Driver emits an OTLP probe

The driver MUST send a single OTLP trace export probe via Python
`urllib.request.urlopen` with :
- Method : POST
- URL : `http://127.0.0.1:4318/v1/traces`
- Content-Type : `application/x-protobuf`
- Header : `traceparent: 00-{tid}-{sid}-01` where `{tid}` and `{sid}`
  are deterministic placeholders (`a`-repeated 32 chars / `b`-repeated
  16 chars) — chosen so the capture is reproducible.
- Body : a pre-canned protobuf payload (hex-encoded constant in the
  driver) carrying `resource.attributes.service.name = "fsm-backend"`
  and one `ResourceSpans` record.

##### FR-T5-OLR-023 — Driver asserts service.name capture

After emission, the driver MUST read the most recent
`capture-NNN.json` and `grep -q '"service_name": "fsm-backend"'`. Fail
the driver exit code if absent.

##### FR-T5-OLR-024 — Driver asserts traceparent forwarding

The driver MUST `grep -q '"traceparent": "00-aaaaa.*-01"'` (regex)
in the capture. Fail if the `traceparent` header was not echoed.

##### FR-T5-OLR-025 — Driver asserts resource_spans_count ≥ 1

`grep -q '"resource_spans_count": [1-9]'` in the capture. Fail if the
embedded payload was empty.

##### FR-T5-OLR-026 — Driver exit codes

- Exit 0 : all assertions PASS.
- Exit 1 : collector failed to start (readiness timeout) OR an
  assertion failed.
- Exit 2 : missing toolchain (no `python3` on PATH).

Exit code is the **single source of truth** for the harness gate.

##### FR-T5-OLR-027 — Driver `--out` accepts a tmpdir

The driver accepts `--out DIR` and defaults to
`mktemp -d -t fsm-live-run-XXXXXX`. Captures persist to that
directory ; the driver echoes the directory on exit for the
harness to consume.

##### FR-T5-OLR-028 — Driver `--probe-only` mode

`run_smoke.sh --probe-only` MUST skip the collector start (assume
something else is already on `:4318`), send the probe, and exit. The
docker-compose mode uses this against the real collector.

---

#### Cluster 3 — Golden captures (FR-T5-OLR-040..043)

##### FR-T5-OLR-040 — Direct-path golden capture committed

`.forge/changes/t5-otel-live-run/captures/direct.golden.json` MUST
exist with the deterministic capture for the direct-path probe
(no Kong hop). Schema matches FR-T5-OLR-006.

##### FR-T5-OLR-041 — Kong-path golden capture committed

`.forge/changes/t5-otel-live-run/captures/kong.golden.json` MUST
exist with the deterministic capture for the Kong-path probe (probe
carries the same `traceparent` header simulating Kong's verbatim
forwarding).

##### FR-T5-OLR-042 — Golden README

`.forge/changes/t5-otel-live-run/captures/README.md` MUST document
how to regenerate the goldens (`bash test/live-run/run_smoke.sh`),
the sanitisation rules applied, and the deterministic placeholder
values (`a`-repeated traceId / `b`-repeated spanId).

##### FR-T5-OLR-043 — Sanitisation evidence

Every committed golden MUST contain the literal `"<ts:redacted>"`
string (proof the timestamp sanitiser ran). Every committed golden
MUST NOT contain any 4-octet IPv4 pattern (asserted by the harness
via grep).

---

#### Cluster 4 — BDD feature `traceparent_live_run.feature` (FR-T5-OLR-060..064)

##### FR-T5-OLR-060 — Feature file exists

`examples/forge-fsm-example/test/features/traceparent_live_run.feature`
MUST exist as a NEW Gherkin feature distinct from Phase C's
`traceparent_e2e.feature` (which NFR-T5-TPE-004 hard-pins). Audit
header `<!-- Audit: T.5 (t5-otel-live-run) — Phase D live-run
collector contract validation -->`.

##### FR-T5-OLR-061 — Two named scenarios

The file MUST declare exactly two scenarios :

1. **Scenario** : `Live capture — fake collector receives OTLP export
   with the expected service.name`
2. **Scenario** : `Live capture — captured trace carries a W3C
   traceparent linking parent and child spans`

##### FR-T5-OLR-062 — Gherkin discipline

Each scenario has ≥ 1 Given / When / Then. Background block allowed.

##### FR-T5-OLR-063 — Symbol forward-pointer

At least one step MUST reference Phase B symbols by name —
`HeaderMapExtractor` OR `MetadataMapCarrier` OR `HeaderMapCarrier`.

##### FR-T5-OLR-064 — Cross-reference comment

The feature file header MUST cross-reference Phase C's
`traceparent_e2e.feature` (Phase C, FR-T5-TPE-001..010) so future
readers see the chain.

---

#### Cluster 5 — L1 harness `t5-otel-live-run.test.sh` (FR-T5-OLR-080..088)

##### FR-T5-OLR-080 — Harness exists

`.forge/scripts/tests/t5-otel-live-run.test.sh` MUST exist mirroring
the Phase C `t5-otel-traceparent-e2e.test.sh` layout (bash header,
source `_helpers.sh`, PASS/FAIL counters, `--level 1,2` parsing,
`print_summary`).

##### FR-T5-OLR-081 — L1 test : driver + collector files exist

`_test_olr_001_driver_files_exist` asserts both `run_smoke.sh` and
`fake_otlp_collector.py` exist with audit headers.

##### FR-T5-OLR-082 — L1 test : collector is stdlib-only

`_test_olr_002_collector_stdlib_only` greps the collector script
and asserts it does NOT import `protobuf`, `grpc`, `requests`, or
any other known third-party module.

##### FR-T5-OLR-083 — L1 test : smoke driver runs to completion

`_test_olr_003_smoke_driver_runs` runs the driver against a tmpdir
and asserts exit 0 + at least one `capture-NNN.json` appears.
Skips cleanly if `python3` is absent.

##### FR-T5-OLR-084 — L1 test : capture matches direct golden

`_test_olr_004_capture_matches_direct_golden` runs the driver and
asserts `diff -q <capture> direct.golden.json` returns 0
(byte-identical, deterministic sanitisation).

##### FR-T5-OLR-085 — L1 test : capture matches kong golden

`_test_olr_005_capture_matches_kong_golden` runs the driver with
`--scenario kong` and asserts `diff -q` against `kong.golden.json`.

##### FR-T5-OLR-086 — L1 test : feature file presence + shape

`_test_olr_010_feature_file_exists` asserts the feature file exists,
carries the audit header, declares exactly 2 `Scenario:` lines, has
`Feature:` + Given/When/Then per scenario, and references a Phase B
symbol.

##### FR-T5-OLR-087 — L1 test : goldens are sanitised

`_test_olr_020_goldens_sanitised` asserts both committed goldens
contain `"<ts:redacted>"` AND contain no IPv4 dotted-quad pattern.

##### FR-T5-OLR-088 — L1 test : CI matrix entry

`_test_olr_030_ci_matrix_entry` asserts `forge-ci.yml` lists
`t5-otel-live-run.test.sh` immediately after
`t5-otel-traceparent-e2e.test.sh` with `--level 1`.

---

#### Cluster 6 — L2 docker-compose smoke (FR-T5-OLR-100..102)

##### FR-T5-OLR-100 — Docker-compose live-run config exists

`examples/forge-fsm-example/test/live-run/docker-compose.live-run.yml`
MUST exist booting `fsm-otel-collector` ONLY (the minimal stack for
collector-contract validation). Adopters wishing to add backend +
Kong can extend it ; the canonical reference is the otel-collector
on its own.

##### FR-T5-OLR-101 — L2 test : docker leg opt-in

`_test_olr_l2_001_docker_compose_smoke` MUST gracefully skip when
EITHER `docker compose` is absent OR `FORGE_LIVE_RUN_DOCKER` env is
not set to `1`. When activated, it boots the docker-compose file,
runs `run_smoke.sh --probe-only`, and asserts a healthy capture.

##### FR-T5-OLR-102 — Documentation discoverability

`examples/forge-fsm-example/test/live-run/README.md` MUST document
both modes (fake-collector hermetic + docker-compose opt-in), the
env toggle (`FORGE_LIVE_RUN_DOCKER=1`), and the 1-line command for
each.

---

#### Cluster 7 — CI registration (FR-T5-OLR-120)

##### FR-T5-OLR-120 — `forge-ci.yml` matrix entry

`.github/workflows/forge-ci.yml` `harness` job MUST register
`t5-otel-live-run.test.sh` immediately after
`t5-otel-traceparent-e2e.test.sh` with `--level 1`. The step name
MUST be `t5-otel-live-run.test.sh` for shell-grep auditability.
Adding the step MUST keep total file length ≤ 300 lines
(NFR-CI-002).

---

#### Cluster 8 — Documentation (FR-T5-OLR-140..142)

##### FR-T5-OLR-140 — `CHANGELOG.md` entry

`CHANGELOG.md` `## [Unreleased]` MUST gain an entry naming :
the smoke driver, the fake collector, the golden captures, the new
BDD feature, the harness, and the docker-compose opt-in.

##### FR-T5-OLR-141 — `docs/new-archetypes-plan.md` Phase D row

`docs/new-archetypes-plan.md` MUST gain a Phase D row under T.5
acknowledging the live-run leg as shipped (mirror the row shape of
Phase B / Phase C entries).

##### FR-T5-OLR-142 — `.forge/product/roadmap.md` inventory

`.forge/product/roadmap.md` Phase 3 inventory MUST gain a
`t5-otel-live-run archivé 2026-05-12` bullet mirroring the
`t5-otel-traceparent-e2e` bullet shape.

---

### Non-Functional Requirements

#### NFR-T5-OLR-001 — Performance budget (harness L1)

`t5-otel-live-run.test.sh --level 1` MUST complete in ≤ 10 s
wall-clock on a standard developer laptop (M-class macOS or x86_64
Linux). The smoke driver itself MUST complete in ≤ 3 s when
collector is local + already-listening.

#### NFR-T5-OLR-002 — Backward compatibility

After this change, `t5-otel-app.test.sh`, `t5-otel-traceparent-e2e.test.sh`,
and `t5-otel-stack.test.sh` MUST still exit 0. No regression on
prior phases.

#### NFR-T5-OLR-003 — Article V audit trail

Every task in `tasks.md` MUST carry a `[Story: FR-T5-OLR-XXX]` tag.

#### NFR-T5-OLR-004 — No production app-code edits

This change MUST NOT modify any `.rs` or `.dart` file under
`examples/forge-fsm-example/backend/` or
`examples/forge-fsm-example/frontend/lib/`. Phase B's wiring stands.
Verified by `git diff --stat` review.

#### NFR-T5-OLR-005 — `forge-ci.yml` size budget

After adding the new step, `.github/workflows/forge-ci.yml` MUST be
≤ 300 lines total (NFR-CI-002 inherited).

#### NFR-T5-OLR-006 — Hermetic by default

The L1 path MUST NOT require Docker, internet access, or any
toolchain other than `python3` ≥ 3.8 and bash. CI on Ubuntu runners
runs the full L1 surface without any setup steps beyond the existing
matrix.

#### NFR-T5-OLR-007 — Deterministic golden captures

Golden captures MUST be reproducible byte-for-byte from any host
with `python3` ≥ 3.8. The sanitisation rules (FR-T5-OLR-004) plus
the deterministic probe payload (FR-T5-OLR-022) guarantee this.

#### NFR-T5-OLR-008 — No PII / no IP in captures

Per FR-T5-OLR-004 + FR-T5-OLR-087. Hard constraint — committed
captures are sanitised, byte-stable, and adopter-safe.

---

## BDD Acceptance Criteria

The user-facing surface this change touches is the smoke flow that
produces a healthy OTLP capture. Two Article II scenarios ship
inline below ; `traceparent_live_run.feature` MUST mirror them
verbatim.

```gherkin
Feature: OTel collector contract — live-run captures match the wired SDK shape
  As a Forge full-stack-monorepo archetype consumer
  I want a hermetic smoke flow that emits an OTLP trace and captures it byte-deterministically
  So that adopters have a reproducible reference for the collector boundary contract

  Background:
    Given the fake OTLP collector is listening on "http://127.0.0.1:4318"
    And the smoke driver sends a probe carrying a "traceparent" header "00-{a*32}-{b*16}-01"
    And the probe payload declares "resource.attributes.service.name" = "fsm-backend"

  Scenario: Live capture — fake collector receives OTLP export with the expected service.name
    Given the smoke driver writes captures under a tmp directory
    When the driver completes its single OTLP probe
    Then the latest "capture-NNN.json" contains "service_name": "fsm-backend"
    And the captured payload's "resource_spans_count" is greater than zero
    And the sanitised timestamp placeholder "<ts:redacted>" replaces wall-clock time
    And the capture diffs cleanly against "direct.golden.json"

  Scenario: Live capture — captured trace carries a W3C traceparent linking parent and child spans
    Given the Phase B Rust SDK uses "HeaderMapExtractor" to lift the parent context off the inbound HTTP request
    And the probe simulates a downstream call that already carries an inbound "traceparent"
    When the driver completes its OTLP probe
    Then the latest capture echoes the inbound "traceparent" header in its "traceparent" field
    And the traceparent matches "00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]"
    And the capture diffs cleanly against "kong.golden.json"
    And no IPv4 dotted-quad pattern appears in either golden capture

# TODO(#t5-otel-live-run): step bodies are executed by run_smoke.sh + the
# harness — no cucumber-rs or bdd_widget_test binding is shipped in this
# change. A future change may add real step bindings ; out of scope here.
```

---

## Anti-Hallucination Pass

- **Testable** : every FR maps to at least one assertion in
  `t5-otel-live-run.test.sh` (mapping in `tasks.md`).
- **Unambiguous** : 1 open question flagged (Q-001 protobuf decode
  strategy) resolved by ADR-T5-OLR-001 in `design.md`.
- **Constitution-compliant** : Articles I, II, III, IV, V, VIII, IX,
  XII all honored.
- **Verifiable against Phase C** : symbol names match Phase B's
  `propagation.rs` verbatim ; no new lib pins introduced.
- **Verifiable against Phase A** : OTLP HTTP/protobuf `:4318` matches
  `otel-collector-config.yaml` receiver block verbatim.

---

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none. One question in
`open-questions.md` :

- **Q-001** (protobuf decoding strategy) → resolved by
  ADR-T5-OLR-001 (stdlib walker, no pip dep).
