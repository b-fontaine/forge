# Open Questions — t5-otel-stack

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Sampler location — collector-side `tail_sampling` vs SDK head-based?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-OTEL-030
- **Raised on**: 2026-05-08
- **Raised by**: @bfontaine

### Question

`observability.yaml::sampler` mandates `parentbased_traceidratio`
with env-tier ratios (prod 0.1, staging 1.0, dev 1.0). Two
locations to apply the ratio :

- **Option A** : collector-side
  `processors.tail_sampling` (or
  `processors.probabilistic_sampler` with `parent_based`) inside
  `infra/observability/otel-collector-config.yaml.tmpl`. Env-tier
  overlays (`infra/k8s/overlays/{prod,staging,dev}/sampler-patch.yaml.tmpl`)
  patch only the ConfigMap → no app rebuild loop.
- **Option B** : SDK head-based — each app instrumentation
  pipeline declares the sampler with the ratio coming from an env
  var. Lower collector-side load (already-rejected spans are never
  exported) but ratio change requires app redeploy.

Lean **A** for the env-overlay ergonomics — Phase A is infra-only,
SDK setup belongs to Phase B (instrumentation), so locking the
mechanism collector-side keeps Phase A self-contained.

Resolve at `/forge:design` after Context7 review of OTel collector
v0.110+ processor support (especially `tail_sampling_processor`
maturity and the `parentbased_traceidratio` semantics under it).

### Resolution

- **Resolved on**: 2026-05-09 (via `design.md` ADR-OTEL-001)
- **Decision**: **Option A — collector-side
  `processors.probabilistic_sampler`** with
  `attribute_source: traceID` + `mode: proportional` +
  `hash_seed: 22`. Env-tier overlays patch only `sampling_percentage`
  (dev/staging 100, prod 10).
- **Rationale**: Context7 review of
  `/open-telemetry/opentelemetry-collector-contrib` confirmed the
  `probabilistic_sampler` is the simpler, ratio-flat processor that
  matches `parentbased_traceidratio` semantics most closely WITHIN
  the collector-side constraint. `tail_sampling_processor` is a
  full policy engine (errors / latency / route filters), overkill
  for a flat ratio. The `parent_based` part of the standard's
  intent comes for free in the dual-stage Phase A + Phase B model :
  Phase B SDK ships `parentbased_traceidratio` head-side ; Phase A
  collector ships ratio-only tail-side ; spans entering the
  collector are post-decision so the ratio re-application is
  deterministic via trace ID. Documented for adopter clarity in
  `infra/CLAUDE.md.tmpl`.

---

## Q-002: Exact upstream image tags for OBI and Coroot?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-OTEL-007 / FR-OTEL-021
- **Raised on**: 2026-05-08
- **Raised by**: @bfontaine

### Question

FR-OTEL-007 + FR-OTEL-021 forbid `:latest` and require an exact
tag. Need to confirm via Context7 + upstream Docker Hub / Helm
chart inspection :

- **OBI** : the project moved from
  `grafana/ebpf-autoinstrument` to
  `grafana/beyla` in 2024 ; verify which name + which tag is
  canonical at 2026-05-08.
- **Coroot** : `coroot/coroot` on Docker Hub. Pick the most
  recent stable.

Apply the **30-day waiver criterion** from ADR-T5-002 : the chosen
tag should be ≥ 30 days old to filter out regressions. If the only
recent stable is < 30 days, apply the waiver pattern from T.5
(footnote in standard + REVIEW.md ledger note).

Resolve at `/forge:design`.

### Resolution

- **Resolved on**: 2026-05-09 (via `design.md` ADR-OTEL-002)
- **Decision**: **OBI = `grafana/beyla:2.0.1`** + **Coroot =
  `coroot/coroot:1.4.4`**. Both pinned exactly. Both > 30 days
  old at design time (Beyla 2.0.1 ≈ 2026-04-01, Coroot 1.4.4 ≈
  2026-03-15).
- **Rationale**: Context7 review of `/grafana/beyla` and
  `/coroot/coroot` (2026-05-08/09) confirmed canonical Docker Hub
  paths + recent stable tags. The `observability.yaml::ebpf_complement:
  opentelemetry-obi` is satisfied by `grafana/beyla` per the
  upstream donation lineage (Grafana donated Beyla to OpenTelemetry
  in 2024 ; the binary is the same codebase). No 30-day waiver
  needed — both pins comfortably past the criterion. Documented in
  `infra/CLAUDE.md.tmpl` for adopter clarity. T-VER-* drift
  verification at impl-time per the T.5 T-VER-006 pattern.

---

## Q-003: Bump `observability.yaml` 1.0.0 → 1.1.0 to record image pins?

- **Status**: answered
- **Raised in**: proposal.md ; specs.md FR-OTEL-080
- **Raised on**: 2026-05-08
- **Raised by**: @bfontaine

### Question

T.5 set the precedent : when an additive realisation introduces
exact pins, the standard YAML bumps minor (e.g.
`transport.yaml::codegen.versions` → 1.1.0). For T5-OTEL, three
shapes to consider :

- **A** : Bump to 1.1.0 with new `versions:` block recording OBI +
  Coroot image tags. REVIEW.md gets an `Updated` ledger entry.
  Symmetric with T.5.
- **B** : Stay at 1.0.0 ; pins live only in the Kustomize
  manifests. The standard's contract is unchanged (it already
  declared `ebpf_complement: opentelemetry-obi` and
  `service_map: coroot` — adding tags is realisation, not
  contract change).
- **C** : Bump to 1.0.1 (PATCH) instead of MINOR — record pins
  but signal "no contract change". SemVer-pure but non-symmetric
  with T.5's MINOR bump.

Lean **A** for symmetry with T.5 + because pins ARE part of the
behavioural surface adopters depend on (image rollback semantics
follow standard SemVer).

Resolve at `/forge:design` together with Q-002 (the pins
themselves).

### Resolution

- **Resolved on**: 2026-05-09 (via `design.md` ADR-OTEL-003)
- **Decision**: **Option A — bump `observability.yaml` 1.0.0 →
  1.1.0** with new `versions:` block recording `beyla: "2.0.1"` +
  `coroot: "1.4.4"`. REVIEW.md gets an `Updated` ledger entry per
  the lifecycle convention. Symmetric with T.5's `transport.yaml`
  1.0.0 → 1.1.0 codegen pinning bump.
- **Rationale**: Image pins ARE part of the behavioural surface
  adopters depend on (image rollback semantics follow standard
  SemVer ; bumping the standard signals "the realisation surface
  changed in a way you should know about"). MINOR (additive) is
  the right SemVer level — no breaking field added, no field
  removed. ADR-006 (D.5) amendment-versioning precedent preserved
  : v1.1.0 is created UNDER Constitution v1.1.0 and stays at
  v1.1.0 (no circular reference). J.7 validator accepts the new
  version once REVIEW.md ledger entry lands (FR-J7-023 full
  ledger scan).
