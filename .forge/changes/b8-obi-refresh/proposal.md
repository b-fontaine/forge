# Proposal: b8-obi-refresh
<!-- Created: 2026-05-29 -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, OBI/Beyla leg) -->
<!-- Trio context: docs/new-archetypes-plan.md §0.8 (sibling 3 of b8-observability-rearch trio) -->
<!-- Pilot precedents: .forge/changes/b8-coroot-rehost/ (archived v0.4.0-rc.3) + .forge/changes/b8-signoz-unified/ (archived v0.4.0-rc.4) -->

## Problem

The `full-stack-monorepo / 1.0.0` archetype ships **OBI eBPF auto-
instrumentation** via the `grafana/beyla:2.0.1` DaemonSet, pinned in
`templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`
and ratified by `.forge/standards/observability.yaml` v2.0.0
(`versions.beyla: "2.0.1"`, no v-prefix per the verbatim convention
documented in the `versions:` block).

Three drivers for the refresh, all surfaced by the B.8.8 trio
verify-then-pin discipline :

1. **Major upstream bump available.** `grafana/beyla:2.0.1` was pinned by
   `t5-otel-stack` (2026-05-09). Upstream has shipped the **3.x line**
   since (target pin `3.15.0`, multi-arch amd64+arm64 on Docker Hub,
   verified against `docker manifest inspect` at `/forge:design`). 3.x
   carries non-trivial Linux capability + RBAC posture changes that
   touch the `unprivileged-with-capabilities` posture ratified at
   `t5-otel-stack` (ADR-OTEL-004).

2. **Stale `last_reviewed` on the standard.** `observability.yaml` was
   bumped v1.1.0 → v1.2.0 by `b8-coroot-rehost` (Coroot host migration,
   2026-05-25) then v1.2.0 → v2.0.0 BREAKING by `b8-signoz-unified`
   (SigNoz rearch, 2026-05-26 → archived 2026-05-28 / v0.4.0-rc.4). Both
   legs explicitly left `versions.beyla` UNCHANGED at `2.0.1` per the
   inline disclaimer at `observability.yaml` § `versions:`
   ("`b8-signoz-unified` MUST NOT modify `versions.beyla` — that pin is
   the duty of sibling 3 `b8-obi-refresh`"). The trio is **incomplete**
   until leg 3 ships.

3. **Trio closure — known-issue and release cadence.** `v0.4.0-rc.4`
   shipped sibling 2 with leg 3 explicitly forward-declared. Closing
   the trio under `v0.4.0-rc.5` keeps the release lineage consistent
   with the trio pattern and prevents leg 3 drifting indefinitely
   (mémoire `shared_standard_sibling_harness_coupling.md` — shared
   standards left half-bumped accumulate sibling-harness coupling
   debt).

The Coroot pilot (`b8-coroot-rehost`, archived v0.4.0-rc.3) and SigNoz
sibling (`b8-signoz-unified`, archived v0.4.0-rc.4) established the
pattern : verify-then-pin against upstream Docker Hub, 4-copy mirror
sync, L2 manifest-pull harness leg, additive `Updated` ledger entry on
`REVIEW.md` (or `ARCH-CHANGE` flag if breaking — not applicable here).
This proposal applies the established pattern at lower complexity than
sibling 2 — single component, additive bump, no breaking schema shift.

## Solution

Single-component infra refresh, scoped to **OBI / Beyla only** :

1. **Bump** `templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`
   image pin `grafana/beyla:2.0.1` → `grafana/beyla:3.15.0`. Verify
   multi-arch (amd64+arm64) via `docker manifest inspect` at
   `/forge:design` (verify-then-pin discipline, lesson T5.3.2).
   `[NEEDS CLARIFICATION: confirm 3.15.0 is the latest stable line on Docker Hub at design phase — Q-001]`

2. **Aegis re-audit** the DaemonSet posture per ADR-OTEL-004 :
   - Linux capabilities currently set : `BPF`, `SYS_PTRACE`, `NET_RAW`,
     `CHECKPOINT_RESTORE`, `DAC_READ_SEARCH`, `PERFMON`, `NET_ADMIN`,
     `SYS_ADMIN` (drop ALL otherwise).
   - Verify the Beyla 3.x docs against this exact list ; tighten if
     possible, document if widened.
     `[NEEDS CLARIFICATION: Beyla 3.x capability requirements vs 2.x — Q-002]`
   - RBAC : ServiceAccount + ClusterRole read-only on
     pods/nodes/replicasets + ClusterRoleBinding. Confirm no new API
     groups required by 3.x.
     `[NEEDS CLARIFICATION: Beyla 3.x RBAC delta vs 2.x — Q-003]`
   - `nodeSelector: forge.dev/kernel-min-58: "true"` (ADR-OTEL-007).
     Verify Beyla 3.x kernel floor — may have lifted to 6.x.
     `[NEEDS CLARIFICATION: Beyla 3.x minimum kernel — Q-004]`

3. **Bump** `.forge/standards/observability.yaml` **v2.0.0 → v2.1.0
   additive** :
   - UPDATE `versions.beyla: "2.0.1"` → `"3.15.0"` (no v-prefix
     preserved per inline disclaimer).
   - UPDATE `last_reviewed: 2026-05-26 → 2026-05-29`.
   - UPDATE `expires_at: 2027-05-26 → 2027-05-29`.
   - `breaking_change: false` (additive bump only ; no schema field
     surgery, no architectural shift).
   - `pin_review_cadence.beyla: "P12M"` preserved (no cadence change ;
     OBI is slow upstream relative to SigNoz `P30D`).
   - Rationale paragraph extended : Grafana → OTel OBI lineage
     (Beyla is Grafana's open-source contribution to OpenTelemetry OBI
     specification — already documented at v1.1.0 ledger entry).

4. **Append** `REVIEW.md` ledger entry with the **normal `Updated`
   flag** (NOT `ARCH-CHANGE` — that flag is reserved for breaking
   architectural shifts per `b8-signoz-unified` precedent
   FR-B8-SIG-H-006).

5. **4-copy mirror sync** byte-identical (mirror pattern from
   `b8-coroot-rehost`) :
   - `templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`
     (canonical).
   - `cli/assets/templates/full-stack-monorepo/1.0.0/infra/k8s/base/obi-daemonset.yaml.tmpl`
     (cli-bundle .tmpl).
   - `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/...`
     (example-side .tmpl, if mirrored — to confirm at `/forge:design`).
   - `examples/forge-fsm-example/infra/k8s/base/obi-daemonset.yaml`
     (rendered example).
   `[NEEDS CLARIFICATION: confirm exact mirror count — 4 or 6 copies (no docker-compose mirror since OBI is K8s-only) — Q-005]`

6. **Snapshot regen** via `bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`
   (deterministic). Current size 668589 B post-`b8-signoz-unified` ;
   ceiling 716800 B (700 KiB, ADR-B8-SIG-008). Headroom ~47 KB. Beyla
   bump is a pin-only change (no new template files) → expected size
   delta < 100 B. **If exceeded** → ADR + budget bump WAIVER (mirror
   ADR-B8-SIG-008 pattern). `a7.test.sh` 29/29 must stay GREEN
   (forge-upgrade backward compat).

7. **New harness** `.forge/scripts/tests/b8-obi.test.sh` :
   - L1 grep-based assertions (target ≥ 10 tests mirroring
     `b8-coroot.test.sh` 13/13 layout, scaled down — single-component
     scope vs Coroot host migration).
   - L2 opt-in `FORGE_B8_OBI_DOCKER=1` :
     - `docker manifest inspect grafana/beyla:3.15.0` exit 0 (multi-arch).
     - Manifest digest captured to evidence.md.
     - Rotted-pin denied invariant : `docker manifest inspect grafana/beyla:2.0.1`
       still succeeds (Beyla 2.x stays on Docker Hub — Grafana does not
       routinely yank). If yanked → document as evidence of upstream
       discipline.

8. **Sibling-harness coupling resolution.** The lesson
   `shared_standard_sibling_harness_coupling.md` (institutionalised
   2026-05-28 post-`b8-signoz-unified`) mandates : any change bumping
   a shared standard MUST update all sibling harnesses hard-pinning
   the standard's state. Targets identified :
   - `.forge/scripts/tests/t5-otel.test.sh:128` — assertion
     `image: grafana/beyla:2.0.1` → `grafana/beyla:3.15.0`.
   - `.forge/scripts/tests/t5-otel.test.sh:131` — negative assertion
     `image: grafana/beyla:latest` preserved.
   - `.forge/scripts/tests/t5-otel.test.sh:233` — assertion
     `beyla: "2.0.1"` → `beyla: "3.15.0"`.
   - `.forge/scripts/tests/b8-coroot.test.sh::_test_010` — accepted
     `last_reviewed:` date set extended `2026-05-2[5678]` →
     `2026-05-2[56789]` (or wider regex). To audit at `/forge:design`.
   - `.forge/scripts/tests/b8-signoz.test.sh::_test_010` — same.
   `[NEEDS CLARIFICATION: full enumeration of sibling harnesses hard-pinning beyla 2.0.1 or last_reviewed 2026-05-26 — Q-006]`

9. **Register** harness in `.github/workflows/forge-ci.yml::harness`
   matrix. NFR-CI-002 plafond 300 lignes — already at 300/300 post
   `b8-signoz-unified` ; **comment compression required** (lesson
   T5.3.3 ADR-T533-002, mirror to free a slot for the new harness
   entry). `[NEEDS CLARIFICATION: confirm exact line budget impact at /forge:plan — Q-007]`

10. **Demeter pass** during `/forge:design`. Grafana Labs jurisdiction
    is **already** in `cloud-act-publishers.yml` (US, Delaware). No new
    K3-RULE required ; the existing K3-RULE coverage applies to all
    `grafana/*` images. Confirm no T3 substitution flag drift.

11. **infra/CLAUDE.md.tmpl** H2 OBI section — refresh pin reference +
    document any capability/RBAC delta surfaced by Q-002/Q-003.

12. **CHANGELOG** entry under `## [Unreleased]` (release-target
    `v0.4.0-rc.5` section pending `/forge:plan`).

13. **Pre-flip full-CI gate.** Lesson
    `shared_standard_sibling_harness_coupling.md` mandates : full
    `forge-ci.yml` harness matrix MUST run GREEN before flipping
    `planned → implemented`. Specifically : `t5-otel.test.sh`,
    `b8-coroot.test.sh`, `b8-signoz.test.sh`, plus the new
    `b8-obi.test.sh`. The b8-coroot-rehost escape (rc.3 shipped with
    `t5-otel.test.sh` 021/080 RED on main because the leg-1 author
    trusted local harness output) is the institutionalised
    counter-example.

## Scope In

- `grafana/beyla` image pin refresh 2.0.1 → 3.15.0.
- `observability.yaml` additive bump v2.0.0 → v2.1.0
  (`versions.beyla` + `last_reviewed` + `expires_at` only).
- `REVIEW.md` `Updated` ledger entry.
- 4-copy (or 6-copy, TBD Q-005) byte-identical mirror sync.
- Aegis re-audit of caps + RBAC + kernel floor for Beyla 3.x.
- New harness `b8-obi.test.sh` with L1 grep + L2 opt-in manifest pull.
- Sibling harness updates (`t5-otel.test.sh`, `b8-coroot.test.sh`,
  `b8-signoz.test.sh`) to match the new pin and `last_reviewed`.
- `forge-ci.yml` matrix registration + comment compression to stay
  under NFR-CI-002 300-line budget.
- Snapshot regen + `a7.test.sh` backward-compat preservation.
- CHANGELOG `[Unreleased]` entry targeting `v0.4.0-rc.5`.

## Scope Out (Explicit Exclusions)

- **No Coroot or SigNoz changes** — those are legs 1 and 2, archived.
- **No new top-level fields** in `observability.yaml`
  (`pin_review_cadence:` already exists from sibling 2 ; no schema
  surgery).
- **No `breaking_change: true`** — this is an additive minor bump, not
  a structural rearch. `ARCH-CHANGE` ledger flag NOT used.
- **No docker-compose changes** — OBI is K8s-only in the flagship
  archetype (DaemonSet, not a service).
- **No `kong:3.6-alpine` fix** — the residual `dev-up-matrix` RED on
  Kong stays out of trio scope (separate future B.8.x change).
- **No Beyla → grafana/opentelemetry-obi rename** even if upstream
  ships the renamed image — the `grafana/beyla` repo remains the
  canonical pull per `observability.yaml` § `versions:` block.
- **No K3-RULE additions** — Grafana Labs jurisdiction already covered
  by existing `cloud-act-publishers.yml` entries.
- **No Helm chart structural changes** — only the image pin string is
  edited in the DaemonSet manifest.

## Impact

- **Users affected**: every adopter of `full-stack-monorepo / 1.0.0`
  who deploys the OBI DaemonSet — pin refresh is transparent at
  `forge upgrade` (A.7 ledger entry) but kernel floor lift (Q-004) may
  exclude older nodes opting in via `forge.dev/kernel-min-58: "true"`.
- **Technical impact**:
  - 1 standard bumped (`observability.yaml` v2.0.0 → v2.1.0 additive).
  - 1 ledger entry on `REVIEW.md` (`Updated` flag).
  - 1 to 5 mirror files synced (Q-005).
  - 3+ sibling harnesses updated (Q-006).
  - 1 new harness registered (NFR-CI-002 budget impact, Q-007).
  - Snapshot regen, expected delta < 100 B.
- **Dependencies**:
  - `b8-coroot-rehost` archived (depends_on, established pattern).
  - `b8-signoz-unified` archived (depends_on, ARCH-CHANGE precedent +
    `pin_review_cadence` field + sibling-coupling lesson).
  - `t5-otel-stack` archived (initial OBI DaemonSet shipped here).

## Constitution Compliance

- **Article I (TDD)**: harness `b8-obi.test.sh` L1 grep tests written
  RED-first before the image pin edit ; manifest-pull L2 fixture
  asserts upstream availability before claiming GREEN.
- **Article II (BDD)**: not applicable — infra pin refresh, no
  user-facing feature surface.
- **Article III (Specs Before Code)**: `/forge:propose` →
  `/forge:specify` → `/forge:design` → `/forge:plan` →
  `/forge:implement` enforced ; no implementation before `tasks.md`.
- **Article III.4 (Anti-Hallucination)**: 7 Q-NNN scaffolded as
  `[NEEDS CLARIFICATION:]` markers, all resolvable at `/forge:design`
  via `docker manifest inspect` + upstream Beyla 3.x docs (Context7
  resolve `/grafana/beyla` → query docs for capabilities + RBAC +
  kernel floor).
- **Article V (Append-Only Audit)**: `REVIEW.md` `Updated` ledger
  append-only (no edit of prior entries). `versions.beyla` history
  preserved inline via standards-lifecycle.md v1.1.0 birth row
  (immutable).
- **Article XII (Governance)**: standard bump scope-eligible without
  amendment per `standards-lifecycle.md § Bumps` — additive minor
  bump, no `expires_at: never` / `exception_constitutional: true`
  toggle.
- **Anti-self-validation discipline (T5.2 lesson)**: independent
  reviewer pass MUST re-execute `docker manifest inspect` and full
  CI matrix from scratch (no transcript trust), per
  `t5_2_self_validation_lesson.md` and
  `shared_standard_sibling_harness_coupling.md`.

## Open questions (initial scaffold — see `open-questions.md`)

- **Q-001** — confirm `grafana/beyla:3.15.0` is the latest stable on
  Docker Hub at `/forge:design` ; identify yanked tags if any.
- **Q-002** — Beyla 3.x Linux capabilities delta vs 2.x. Tighten if
  possible, document inline if widened.
- **Q-003** — Beyla 3.x RBAC delta vs 2.x. Identify any new API
  groups required.
- **Q-004** — Beyla 3.x minimum kernel — kernel-58 nodeSelector
  still valid, or needs lift to 60+ ?
- **Q-005** — exact mirror copy count (4 vs 6 — depends on whether
  `examples/forge-fsm-example/.forge/templates/.../obi-daemonset.yaml.tmpl`
  is mirrored or not).
- **Q-006** — full enumeration of sibling harnesses hard-pinning
  `beyla: 2.0.1` or `last_reviewed: 2026-05-26`.
- **Q-007** — `forge-ci.yml` line-budget impact (currently 300/300) ;
  comment-compression strategy to free slot for `b8-obi.test.sh`.

## Effort estimate

`S` to `M` — single-component additive bump, lower complexity than
sibling 2 (`b8-signoz-unified` was `L` multi-component breaking
rearch). Bulk of effort = Aegis re-audit + sibling-harness sweep +
full-CI matrix gate, not the pin edit itself.

## Release target

`v0.4.0-rc.5` — closes the **B.8.8 observability rearch trio**
(Coroot + SigNoz + OBI). Residual `dev-up-matrix` Kong RED stays
out of trio scope.
