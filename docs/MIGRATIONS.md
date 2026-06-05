<!-- Audit: B.8.10 (b8-10-migrate-flagship) — flagship 1.0.0→2.0.0 migration runbook -->
# Forge Migrations

This document is the canonical runbook for migrating a scaffolded Forge project
between archetype template-set versions. Each `X.Y.Z → A.B.C` section is the
authoritative walkthrough that the `forge upgrade` exit-7 `[NEEDS MIGRATION:]`
abort points adopters to.

---

## full-stack-monorepo 1.0.0 → 2.0.0

The flagship `full-stack-monorepo` 2.0.0 template-set is an **additive**
evolution of 1.0.0. Nothing from 1.0.0 is removed: Kong, Temporal, and the
REST-bridge all remain in place. The 2.0.0 overlays are applied **in parallel**
so an adopter can graduate to the new stack at their own pace.

> **`forge upgrade` aborts on this jump by design.** A major-version bump
> (`1.x → 2.x`) trips the `_a7_check_version_compat` guard in
> `bin/forge-upgrade.sh`, which emits `[NEEDS MIGRATION: from 1.0.0 to 2.0.0]`
> and exits 7. That abort is intentional — the migration is orchestrated by the
> dedicated script below, not by `forge upgrade`.

### Invocation (doc-only for B.8.10)

The migration is an opt-in, power-user tool driven directly from `bin/`. There
is no `forge migrate-flagship` CLI subcommand yet — the TS surface is deferred to
B.8.15. Always inspect the plan with `--dry-run` first:

```bash
# 1. Preview the full plan — mutates nothing.
bash bin/forge-migrate-flagship.sh --target . --dry-run

# 2. Apply a single phase (or all phases).
bash bin/forge-migrate-flagship.sh --target . --phase 2

# 3. Roll back to the frozen 1.0.0 snapshot if needed.
bash bin/forge-migrate-flagship.sh --target . --rollback
```

Exit-codes: `0` success / `2` usage error / `5` missing tool / `7` precondition
not met / `8` overlay conflicts without `--force`.

### Fresh init scaffolds 2.0.0; existing 1.0.0 projects stay additive

Since **B.8.14** (`b8-14-promotion-flip`) the 2.0.0 schema is `stage: stable` +
`scaffoldable: true` — it was `scaffoldable: false` (candidate) until that flip,
so before B.8.14 `forge init` scaffolded 1.0.0 — so a fresh
`forge init --archetype full-stack-monorepo` now scaffolds the **2.0.0 Kong-less /
Envoy Gateway** tree (Constitution v2.0.0 §VIII.1, Amendment #2). EXISTING 1.0.0
projects are never force-migrated:
`forge upgrade` still aborts the major jump (above), and
`forge-migrate-flagship` stays **additive forever** — it applies the 2.0.0
overlays in parallel and never removes Kong / Temporal / the REST-bridge from a
1.0.0 adopter's tree. Kong removal happens ONLY in fresh 2.0.0 scaffolds, never
on migration (§VIII.1 is not retroactive).

### The 4-phase walkthrough

#### Phase 0 — preflight (precondition gate)

Asserts the target is a clean, scaffolded 1.0.0 full-stack-monorepo before any
overlay is touched:

- reads `<target>/.forge/scaffold-manifest.yaml` and requires
  `archetype: full-stack-monorepo` + `archetype_version: 1.0.0` (else exit 7);
- requires a clean Git working tree (else exit 7; override with `--force`);
- verifies the frozen `1.0.0.tar.gz` snapshot sha256 against its companion
  `1.0.0.sha256` (else exit 7 — refuses to run against a corrupted BASE).

With `--dry-run`, Phase 0 prints the plan (target, from/to versions, the 5
additive deltas) and mutates nothing.

#### Phase 1 — observability + contracts (idempotent)

A verification gate. The flagship 1.0.0 already ships the SigNoz/OBI/Coroot
observability trio (closed at B.8.8) and the Connect-RPC codegen overlays
(B.8.6). Phase 1 asserts those sentinels are present; if all are present it is a
no-op (`phase_1(phase_1(target)) == phase_1(target)`). Any genuinely-missing
overlay is applied additively by the Phase 2 classifier. Re-running produces no
diff.

#### Phase 2 — structural overlay (additive)

Applies the five additive-first 2.0.0 deltas via the **sourced**
`bin/forge-upgrade.sh` 3-way merge engine (`_a7_classify` /
`_a7_three_way_merge`) — one merge engine, no duplication. The merge BASE is the
frozen 1.0.0 snapshot; the merge RIGHT is the 27-file 2.0.0 template-set:

| Delta | Source brick | 2.0.0 overlay |
|-------|--------------|---------------|
| Kong → Envoy Gateway | B.8.4 | `infra/k8s/envoy-gateway/` |
| REST-bridge → Connect-RPC | B.8.6 | `backend/crates/grpc-api/` + `shared/protos/` |
| implicit-auth → Zitadel | B.8.7 | `infra/zitadel/` |
| no-web → Qwik web-public | B.8.9 | `frontend/web-public/` |
| postgres-16 → 17 + pgvector | B.8.5 | `infra/postgres/` |

**Additive-first posture.** Kong, Temporal, and the REST-bridge templates are
preserved. B.8.14 performs the breaking removal and the VIII.1/VIII.2
Constitution amendment — not this script.

**Orchestration note (B8O / ADR-B8O-001).** The proposed
`temporal-intent → embedded-orchestration` migration delta is **cancelled** (not
deferred): Temporal is retained as the Rust orchestrator. This script does not
scaffold, run, or reference that cancelled alternative backend — there is no such
template in the 2.0.0 set to apply.

With `--dry-run`, Phase 2 lists per-file actions (`upgraded` / `merge` /
`new`) and mutates nothing. On a real apply it appends one record to the
manifest `upgrade_history` list with `kind: flagship-migration` (identity fields
frozen, append-only) and stamps a `SOURCE_DATE_EPOCH`-deterministic date.

##### Canary cutover — Kong → Envoy, by route (manual)

Phase 2 places Envoy Gateway **in parallel** with Kong; it generates **no**
per-route canary traffic weights. The Kong → Envoy cutover is an adopter-driven,
graduated, per-route process. Shift `HTTPRoute` weights route-by-route, e.g.:

```yaml
# Envoy Gateway HTTPRoute — graduate one route from Kong (90%) to Envoy (10%).
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: greeter-canary
spec:
  rules:
    - backendRefs:
        - name: greeter-kong
          weight: 90
        - name: greeter-envoy
          weight: 10
```

Increase the Envoy weight as confidence grows. A **complete** canary needs Envoy
SecurityPolicy / JWT OIDC wiring, which is deferred to **B.8.12** — do not treat
the parallel Envoy overlay as production-ready auth until then.

#### Phase 3 / 4 — forward-reference stubs

Invoking `--phase 3` or `--phase 4` prints an informational stub and exits 0; no
overlay runs. See the stub sections at the end of this document.

### Rollback

`--rollback` restores the **full** target tree from the byte-frozen 1.0.0
snapshot at `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`. The
snapshot and its `.sha256` are **never** rebuilt or overwritten. `--rollback` is
mutually exclusive with `--phase` (full-snapshot restore only); `--rollback
--dry-run` prints the restore plan and exits 0 without touching the target.

**Rollback criteria — see the full runbook in [`docs/ROLLBACK.md`](ROLLBACK.md) (B.8.13).** Trigger thresholds:

- p99 latency increases by more than 20% after the Envoy cutover → roll back the
  Kong → Envoy route weights;
- traceparent propagation errors exceed 1% → roll back the OTel SDK overlay only.

(The cancelled orchestration-swap leg per B8O contributes **no** CPU-based
rollback criterion.)

### Latency measurement methodology (p50/p95/p99)

<!-- Audit: B.8.12 (b8-12-e2e-migration) — latency measurement methodology;
     ADR-B812-001. NO committed number (III.4 + ADR-B8-1-002). -->

**B.8.12** ratifies the honest before/after gate for this migration as a
**span-inventory superset**, not a committed latency figure. The committed
artifacts are the span inventories
(`.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml` →
`.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml`):
the 1.0.0 three-span set is a strict subset of the 2.0.0 set, and the phantom
Flutter `user.interaction` root is absent from both.

Real p50/p95/p99 latency **cannot** be captured from the committed reference
example, because `fsm-backend` ships as `image: scratch` (B8-BASELINE §3,
FR-B8-1-012). No p50/p95/p99 number is committed anywhere in this brick
(ADR-B8-1-002 + Constitution Article III.4) — only the procedure and the
**relative** rollback thresholds below.

**When a real backend image exists** (B.8.13+), measure latency with the
deterministic procedure in `docs/B8-BASELINE.md §6` (Re-measurement methodology):

1. Stand up the migrated stack against a real backend image (not `scratch`).
2. Drive a representative load through the Connect/gRPC happy-path
   (`demo-005-connect-greeting` round-trip), capturing spans via the hermetic
   fake-OTLP collector (`examples/forge-fsm-example/test/live-run/`).
3. Read p50/p95/p99 from the exporter/collector for the before (Kong route) and
   after (Envoy route) cutover — these are measured at run-time, never committed
   to the repo.
4. Compare against the **B.8.13** rollback thresholds (relative deltas only):
   - **p99 latency** regression **> 20 %** after the Envoy cutover → roll back
     the Kong → Envoy route weights;
   - **traceparent propagation errors > 1 %** → roll back the OTel SDK overlay
     only.

**Opt-in leg.** The `b8-12.test.sh` harness exercises this methodology flow
under `FORGE_B8_12_LIVE=1` (the L2 leg drives the fake-OTLP collector and reads
the methodology doc). Without the env var — and on CI, which ships no
cargo/flutter/docker toolchain — the leg **skip-passes** (it contributes zero
failures). This keeps the gate honest without ever fabricating a latency number.

---

## Phase 3 — T7 new archetypes (forward reference — not yet delivered)

Phase 3 will orchestrate adoption of the new archetypes introduced in T7. It is
a forward-reference stub in B.8.10: `--phase 3` prints this pointer and exits 0.

## Phase 4 — T8 deprecation (forward reference — not yet delivered)

Phase 4 will orchestrate the T8 deprecation plan (the breaking removal of Kong /
Temporal / REST and the VIII.1/VIII.2 Constitution amendment, tracked under
B.8.14). It is a forward-reference stub in B.8.10: `--phase 4` prints this
pointer and exits 0.
