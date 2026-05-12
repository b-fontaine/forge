# Open Questions — i5-compliance-workflow

<!--
Tracking file per Article III.4 mechanisation.
Q-NNN sequential per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Exit code aggregation under mixed-tier severities

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I5-CW-080..082
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The reusable workflow runs four scripts, each with its own
tier-scaled severity envelope :

- **Demeter** (`bin/forge-demeter-scan.sh`) — exit `3` = BLOCKED on
  T2 High or T3 Critical findings ; exit `0` = CLEARED ; exit `2` =
  no lockfile / usage error.
- **Constitution linter** (`bash .forge/scripts/constitution-linter.sh`
  with `ADR-I3-001 T3-Forbidden Components` section) — tier-scaled :
  T1/T2 → WARN (no exit code impact Phase A), T3 → FAIL (exit `1`).
- **SBOM** (`bin/forge-sbom.sh`) — exit `0` on success ; exit `1` =
  no lockfile (non-fatal per I.6 FR-I6-CA-019).
- **Bundle** (`bash .forge/scripts/compliance/bundle.sh`) — exit `0`
  on success ; exit `1` = missing source artefact (fatal — the
  workflow cannot proceed without the bundle).

How does the workflow aggregate these into a final exit code ?

- **Option A — Fail on any non-zero from any step**. Strictest.
  Risks false-positives : the SBOM step exits 1 when no lockfile
  is present (a common state for pure-doc projects). Adopters
  would have to opt out per step.
- **Option B — Tier-aware aggregation**. Inspect each step's
  outcome AND the declared `eu-tier`. At T1/T2, SBOM exit 1 (no
  lockfile) is a warning ; at T3, the same exit becomes fail
  (T3 declares 100% EU jurisdiction — a project without lockfiles
  is by definition not auditable).
- **Option C — Trust each script's tier scaling end-to-end**.
  Demeter and the linter already scale by tier internally ; the
  SBOM and bundle scripts emit warnings the workflow treats
  uniformly. The workflow simply propagates the maximum exit
  code observed.

Lean **C** because it preserves the each-script-owns-its-tier
invariant. Demeter and the linter already encode the tier-scaled
fail/warn line ; the workflow does not re-litigate. SBOM "no
lockfile" remains non-fatal at every tier (matching I.6
FR-I6-CA-019 precedent), with a `::warning::` GitHub Actions
annotation for visibility.

### Resolution

**Resolved by ADR-I5-CW-001** in `design.md`. Decision : **Option C
— trust each script's tier scaling end-to-end**. The workflow's
final exit code is the maximum of the four step exit codes,
re-mapped to `0` / `1` :

- `0` if all four steps exited `0` (clean) or if the only
  non-zero exit is SBOM exit `1` (no lockfile — non-fatal,
  emits `::warning::`).
- `1` otherwise (any of : Demeter exit `3`, linter exit `1`,
  bundle exit `1`, bundle exit `2`, or any script `≥ 2` other
  than the SBOM no-lockfile case).

Demeter's exit `3` aggregates as workflow exit `1` (failed) — the
distinction `3 vs 1` is internal-script granularity not carried
into the workflow envelope (mirrors how GitHub Actions step
`continue-on-error: false` collapses every non-zero into a step
failure).

---

## Q-002: SOURCE_DATE_EPOCH source for bundle determinism

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I5-CW-050
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The bundle script (`bash .forge/scripts/compliance/bundle.sh`)
uses `SOURCE_DATE_EPOCH` for byte-identical output across runs.
The reusable workflow must export this env var. Three options for
the source value :

- **Option A — `github.event.head_commit.timestamp`** : the commit
  timestamp of the HEAD that triggered the workflow. Stable across
  re-runs of the same commit ; varies across commits. Only
  available on push events ; absent on `workflow_call` from
  external invocations.
- **Option B — `github.run_started_at`** : ISO-8601 timestamp of
  when the workflow run started. Differs across re-runs of the
  same commit (each re-run gets a new timestamp). Always
  available.
- **Option C — additional `inputs.epoch` (optional)** : the calling
  workflow can supply a custom epoch ; default to A or B if
  unset.

Trade-off : A is the most reproducible (re-running CI on a commit
produces identical bundle bytes) but not always available. B is
always available but produces drift across re-runs. C is most
flexible but adds an input field.

Lean **A with B fallback**, no additional input. The workflow
resolves `SOURCE_DATE_EPOCH` in a bash step :

```bash
if [ -n "${{ github.event.head_commit.timestamp }}" ]; then
  EPOCH=$(date -d "${{ github.event.head_commit.timestamp }}" +%s)
else
  EPOCH=$(date -d "${{ github.run_started_at }}" +%s)
fi
export SOURCE_DATE_EPOCH="$EPOCH"
```

### Resolution

**Resolved by ADR-I5-CW-002** in `design.md`. Decision : **Option A
with B fallback**. The workflow does NOT expose `epoch` as an
input — the source is GitHub's commit / run metadata, period.
This keeps the input surface minimal and matches the
`SOURCE_DATE_EPOCH` discipline documented in
`global/sbom-policy.md::Regeneration cadence` (commit timestamp is
the canonical input).

---

## Q-003: L2 act-runner integration — opt-in mechanism

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-I5-CW-114
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The L2 fixture for `i5.test.sh` ideally runs the workflow via
`act` (nektos/act, the GitHub Actions local runner) against a
synthetic fixture repo. `act` is not installed on every dev
laptop nor on every CI runner. Three options :

- **Option A — Mandatory `act`**. L2 fails if `act` is not on
  `$PATH`. Aligns with strict TDD ; rejects environments without
  the tool.
- **Option B — Skip-when-absent**. L2 is opt-in via
  `FORGE_I5_ACT=1` env var ; if the var is set but `act` is
  not on `$PATH`, the test prints `[INFO: act not installed,
  skipping L2]` and PASSes (skip = pass). Otherwise the L2 test
  is not even attempted unless `--level 2` is passed.
- **Option C — Synthetic fixture only, no act**. The L2 test
  parses the workflow file with PyYAML, builds an in-memory
  expected step graph, and asserts the parsed YAML matches —
  without actually executing the workflow. Like the i6
  determinism test but for workflow structure.

Trade-off : A is hardest to satisfy in CI environments. B is the
i6 `FORGE_I6_DOCKER=1` precedent. C gives no real fidelity over
the L1 grep tests (the workflow is YAML — grep already validates
its shape).

Lean **B** because the precedent (`FORGE_LIVE_RUN_DOCKER=1` for
`t5-otel-live-run`, `FORGE_I6_DOCKER=1` if it existed) is
opt-in env-var gating with skip-when-absent. The harness defaults
to L1-only ; passing `--level 2` AND `FORGE_I5_ACT=1` AND having
`act` on `$PATH` is what triggers the real execution.

### Resolution

**Resolved by ADR-I5-CW-003** in `design.md`. Decision : **Option
B — opt-in via `FORGE_I5_ACT=1` env var, skip-when-absent
semantics**. The L2 test :

1. Default : skipped (not even attempted) unless `--level 2` or
   `--level 1,2` is passed.
2. When `--level` includes `2` :
   a. If `FORGE_I5_ACT != 1`, the test prints `[INFO: L2 act
      run gated by FORGE_I5_ACT=1, skipping]` and returns 0
      (PASS as skip).
   b. If `FORGE_I5_ACT=1` but `command -v act` is absent, the
      test prints `[INFO: act not installed on PATH, skipping]`
      and returns 0 (PASS as skip).
   c. If both gates pass, the test materialises a tmpdir
      fixture, copies the workflow YAML + minimal scripts into
      it, runs `act workflow_call` with `--input eu-tier=T2`,
      and asserts exit 0.

This mirrors the `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
precedent verbatim.
