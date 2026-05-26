# Proposal: b8-coroot-rehost
<!-- Created: 2026-05-24 -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, Coroot leg) -->
<!-- Trio context: .forge/_memory/b8-observability-rearch-exploration.md §5.1 -->

> **CORRECTION NOTICE (2026-05-25)** : the verify-then-pin claim
> in this proposal that "GHCR forces v-prefix on tags
> (`v1.20.2`, not `1.20.2`)" was **inverted**. The true convention
> for `ghcr.io/coroot/coroot` is **no v-prefix** — the unprefixed
> `1.20.2` is the valid tag ; `v1.20.2` returns `manifest unknown`.
> The mis-read was caught at `/forge:implement` Phase 6 by the L2
> manifest-pull fixture. The authoritative records are
> `design.md::ADR-B8-COR-001` (rewritten), `open-questions.md::Q-001`
> (resolution flipped), `evidence.md` § 1 (corrected transcripts),
> `CHANGELOG.md` (corrected entry) and `REVIEW.md` (corrected entry).
> This proposal is preserved as-is per Article V (history) ; the
> v-prefix claims below are the inverted version and SHOULD be read
> with the correction notice in mind.

## Problem

The `full-stack-monorepo / 1.0.0` archetype ships Coroot via
`infra/k8s/base/coroot-deployment.yaml.tmpl` pinned to
**`coroot/coroot:1.4.4`**, and `.forge/standards/observability.yaml` v1.1.0
declares `versions.coroot: "1.4.4"` (ratified by `t5-otel-stack` 2026-05-09,
ADR-OTEL-002 + ADR-OTEL-003). Two failures surfaced 2026-05-24 by the
verify-then-pin pass institutionalised after T5.3.2 ABANDONED :

1. **Public access denied on Docker Hub.** `docker manifest inspect
   coroot/coroot:1.4.4` returns `denied: requested access to the resource is
   denied / unauthorized: authentication required`. `coroot/coroot:latest`
   returns the same error. The repository under `docker.io/coroot/coroot`
   is no longer publicly pullable from any kubelet without credentials. Any
   adopter scaffolding the flagship today inherits a
   `coroot-deployment.yaml` that **fails ImagePull** in any cluster.
2. **Hosting migrated to GHCR with v-prefixed tag convention.** The
   official Coroot compose
   (`https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml`)
   declares `image: ghcr.io/coroot/coroot${LICENSE_KEY:+-ee}`.
   `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` returns a valid
   multi-arch OCI index (amd64 + arm64). The convention is **v-prefixed**
   (`v1.20.2`, not `1.20.2` — `manifest unknown` on the unprefixed form).
   <!-- HISTORICAL : this claim was inverted ; the bulk sed at /forge:implement
        also erased the original `v1.20.2`/`1.20.2` contrast. Restored above
        per Article V history preservation. See CORRECTION NOTICE at top of
        file + design.md::ADR-B8-COR-001 for the corrected convention
        (uniform no-v-prefix). -->.

This is exactly the T5.3.2-style upstream rot the Anti-Hallucination
Platform Verification process (T5.2) was created to catch *before* adopters
discover it as a red CI light. The known issue `v0.4.0-rc.2` (`task validate
dev-up-matrix RED`) is one symptom of the same family but on the SigNoz
side ; this proposal addresses the Coroot leg in isolation as the **first
sub-change of the trio `b8-observability-rearch`** (cf.
`.forge/_memory/b8-observability-rearch-exploration.md`).

Currently-pinned `1.4.4` is also 16 minor releases behind upstream stable
`1.20.2` (released 2026-05-06). Bridging the gap on a host migration is
strictly more economical than two consecutive bumps.

## Solution

Single-component infra refresh, scoped narrowly to **Coroot only** :

1. **Re-host** `infra/k8s/base/coroot-deployment.yaml.tmpl::spec.template.
   spec.containers[].image` from `coroot/coroot:1.4.4` to
   `ghcr.io/coroot/coroot:1.20.2`. Mirror across the 3 downstream copies
   (canonical + example + `cli/assets/` ×2).
2. **Bump** `.forge/standards/observability.yaml` v1.1.0 → **v1.2.0
   additive** (just refresh `versions.coroot` and adopt the v-prefix
   convention upstream). This is **not** the v2.0.0 breaking bump — that one
   is reserved for `b8-signoz-unified` (which is structurally breaking, 4
   services → 5 services). Append the lifecycle entry to
   `.forge/standards/REVIEW.md` per Article XII.
3. **Demeter jurisdiction pass** during `/forge:design`. Coroot Inc is
   US-incorporated ; K3-RULE-001 (T3 forbidden if US-jurisdiction) needs
   evidence-collection to confirm CE / EE / data-plane behaviour. Likely
   outcome (not pre-judged) : CE OK for T1/T2, candidate-substitution flag
   for T3.
4. **New harness** `.forge/scripts/tests/b8-coroot.test.sh` — L1
   grep-based assertions on (i) all 4 copies migrated, (ii) v-prefix tag
   used in `observability.yaml` + manifest, (iii) REVIEW.md entry present
   + dated. L2 opt-in `FORGE_B8_COROOT_DOCKER=1` runs
   `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` to assert the
   pin remains pullable (mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER`
   pattern, ADR-T5-OLR-005).

Decisions reserved for `/forge:design` (resolved as ADRs) :

- **ADR-1** — Tag convention : commit to v-prefixed `1.20.2` form for the
  `coroot` key only (because GHCR convention) ; check whether the rest of
  `observability.yaml::versions` (e.g. `beyla: "2.0.1"`) should align in
  `b8-obi-refresh` or stay heterogeneous.
- **ADR-2** — Jurisdiction posture : T1/T2 CE OK, T3 flagged ; Demeter
  evidence + `K3-RULE-EXT-NNN` if a new rule is warranted.
- **ADR-3** — Coroot agents (`coroot-node-agent`, `coroot-cluster-agent`)
  : confirmed **deferred** ; their absence is what makes Coroot today
  service-map-only without node discovery. Document the limitation, do
  not ship.

Release vehicle : next `0.4.0-rc.x` (probably rc.3, sealed once this
single change archives).

## Scope In

- Edit `.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl` (canonical).
- Mirror to the 3 downstream copies :
  - `examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml`
  - `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl` (if present — to be confirmed in `/forge:design`)
  - `cli/assets/.forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl`
- Bump `.forge/standards/observability.yaml` v1.1.0 → v1.2.0 (`versions.coroot: "1.20.2"`, optional `coroot_registry: "ghcr.io/coroot/coroot"` field if `/forge:design` deems it useful).
- Append a `Updated 2026-05-24` row to `.forge/standards/REVIEW.md`.
- New harness `b8-coroot.test.sh` (L1 grep + L2 manifest-inspect opt-in).
- Register harness in `.github/workflows/forge-ci.yml::harness` matrix (verify ≤ 300-line NFR-CI-002 budget — currently 294/300 per T5.3.3).
- Snapshot tarball regeneration via `bin/forge-snapshot.sh` (SOURCE_DATE_EPOCH deterministic).
- CHANGELOG `[Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **SigNoz unified rearch** → separate sub-change `b8-signoz-unified` (the
  rc.2 known issue blocker, far larger surface : 4 → 5 services + OPAMP +
  ClickHouse 24 → 25 + sqlite app state + UI port 3301 → 8080).
- **OBI / Beyla refresh** → separate sub-change `b8-obi-refresh` (major
  bump 2.0.1 → 3.15.0, capabilities Linux review, Aegis re-audit).
- **`observability.yaml` v2.0.0 breaking bump** → reserved for
  `b8-signoz-unified`. This change ships v1.2.0 additive only.
- **`pin_review_cadence:` constitutional field** → reserved for
  `b8-signoz-unified` (Coroot cadence is slow enough for 12-month loose ;
  SigNoz 2-week cadence is the one that needs the new field).
- **`coroot-ee` paid edition** — out of forge default ; adopters with EE
  license can override locally.
- **`coroot-node-agent` + `coroot-cluster-agent`** — Coroot's official
  compose ships them but forge defers ; absent, Coroot stays
  service-map-only without node discovery. Documented in standard but not
  shipped.
- **Coroot K8s Helm chart** — forge ships a single Deployment manifest, not
  the upstream Helm chart. Out of scope here ; possibly considered in B.8.4
  (Envoy Gateway templates) if a generalised infra-Helm policy is adopted.
- **Compose-dev addition** — Coroot is K8s-only today, the dev compose
  doesn't include it. Out of scope here.
- **Mobile-only archetype** — Coroot is full-stack-monorepo only ;
  mobile-only is untouched.

## Impact

- **Users affected**: every adopter who scaffolded `full-stack-monorepo /
  1.0.0` and is or will be deploying the K8s observability overlay (T2/T3
  self-host postures). T1 adopters running compose-dev only are
  *unaffected functionally* but inherit the standard bump anyway. Mobile-
  only adopters are entirely unaffected.
- **Technical impact**: `S`. Four file edits (canonical + 3 mirrors), one
  standard frontmatter bump + 1 versions entry, one REVIEW row, one
  harness, one snapshot regen, one CHANGELOG entry. No new dependency, no
  new CI job (just one matrix line addition under the existing
  `forge-ci.yml::harness` job).
- **Dependencies**: none upstream. b8-coroot-rehost is the pilot of the
  `b8-observability-rearch` trio. b8-signoz-unified and b8-obi-refresh
  follow independently in any order, both technically uncoupled from this
  one (separate images, separate manifests).
- **Risk level**: **Low**. Host-migration class change ; tag convention
  resolved (v-prefix), image existence verified
  (`docker manifest inspect`), no breaking change to forge's templating
  surface. Single unknown is the **Coroot 1.4 → 1.20 ConfigMap schema
  drift** (16 minor versions of upstream evolution) — mitigated by the L2
  manifest-pull fixture + the fact that forge's templated ConfigMap
  surface is intentionally minimal (the upstream maintains backward
  compatibility on the documented fields).

## Constitution Compliance

### Article I — TDD

RED-GREEN cycle on `b8-coroot.test.sh`. RED first asserts :
1. All 4 copies match the new pin pattern `ghcr.io/coroot/coroot:1.20.2`
   (regex grep).
2. `observability.yaml::versions.coroot` matches `1.20.2` (with v-prefix).
3. `REVIEW.md` carries a dated entry `2026-05-24 / Updated / observability.yaml`.
4. L2 (opt-in) : `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` exit 0
   (manifest still pullable post-archive).

Then GREEN by editing the 4 templates + standard + REVIEW. No code is
written before the test exists and fails as expected.

### Article II — BDD

Not applicable — no user-facing feature. This is an infra-only template
refresh ; the Coroot UI is consumed by operators reading observability data,
not by application users. No Given/When/Then scenario justified.

### Article III — Specs Before Code

Confirmed. The pipeline is `/forge:propose` (this) → `/forge:specify` →
`/forge:design` → `/forge:plan` → `/forge:implement`. No template
modification before `specs.md` is ratified and `design.md` resolves the
three ADRs (tag convention / jurisdiction posture / agents deferral).

### Article VIII — Infra excellence + observability mandate

Refreshing the Coroot pin keeps `observability.yaml` v1.x alive and
ratified per the lifecycle declared in `t4-adr-ratification`. Not
refreshing it leaves Article VIII's "observability is non-negotiable"
clause unenforceable in practice (every adopter would have a broken
Coroot deployment).

### Article XII — Governance

Standards bump v1.1.0 → v1.2.0 additive. REVIEW.md ledger append-only
entry. No constitution amendment needed (the
`pin_review_cadence:` field is deferred to `b8-signoz-unified`). The bump
is well within the `standards-lifecycle.md` v1.1.0 contract.

### Article III.4 — Anti-Hallucination Protocol

Pin sourced from verified upstream evidence collected 2026-05-24 :

- `docker manifest inspect coroot/coroot:1.4.4` ❌ `denied: unauthorized`
- `docker manifest inspect coroot/coroot:latest` ❌ `denied: unauthorized`
- `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` ✅ multi-arch OCI index
- `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` ❌ `manifest unknown` (v-prefix convention confirmed)
- `https://api.github.com/repos/coroot/coroot/releases/latest` → `tag: v1.20.2`
- `https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml` → `image: ghcr.io/coroot/coroot`

All evidence is recorded in `.forge/_memory/b8-observability-rearch-
exploration.md` § 2 and § 7 sources. No symbol or version pin in this
proposal is unsourced.

## Open Questions

Three questions surfaced during proposal authoring, deferred to
`open-questions.md` ; all resolved (`answered`) before this change
reached `status: implemented` (a fourth question Q-002 was added
during `/forge:specify`, not raised here). No `[NEEDS CLARIFICATION:]`
marker inline in this proposal ; markers were converted to **Q-NNN**
references when the change advanced from `proposed` to `implemented`,
per Article III.4 + F.1 discipline.

- **Q-003** — Coroot 1.4 → 1.20 ConfigMap schema diff. Sixteen minor
  versions of upstream evolution between the currently-shipped
  `1.4.4` and the target `1.20.2`. The forge-templated ConfigMap
  surface is small (essentially the bootstrap config + Service name),
  but a manifest-pull L2 fixture should confirm the current rendered
  manifests still deserialise against `1.20.2` without requiring
  template-side edits. To be resolved in `/forge:design` via Atlas
  evidence collection (Coroot CHANGELOG between 1.4.x → 1.20.x review
  + sample apply on a kind cluster). **Resolved 2026-05-25** via
  ADR-B8-COR-003 (grep + L2 manifest-pull, kind deferred to
  `b8-signoz-unified`).

- **Q-004** — Coroot Inc jurisdiction for K3-RULE-001 / T3.
  Coroot Inc is US-incorporated (per Coroot website + GitHub org
  metadata, to be verified). The CE image is OSS under Apache 2.0
  and runs entirely on the adopter's infrastructure, so US-
  jurisdiction risk applies only to (a) maintenance / patching
  responsiveness if Coroot Inc became US-coerced, and (b) any
  telemetry phone-home (Coroot has none in CE per upstream docs,
  to be verified). Demeter pass in `/forge:design` will surface the
  evidence. Likely outcome : T1/T2 CE-OK, T3 candidate-substitution
  flag with a new `K3-RULE-EXT-NNN` if warranted (or none if the
  T1/T2 posture is sufficient). **Resolved 2026-05-25** via
  ADR-B8-COR-004 (Option A — T1/T2 OK, T3 candidate-substitution
  flag in `rationale`, no new K.3 rule in this sub-change).

- **Q-001** — Should `observability.yaml::versions` adopt v-prefix
  uniformly? Currently `versions.beyla: "2.0.1"` (no v-prefix).
  Coroot upstream forces v-prefix on GHCR (`v1.20.2` works,
  `1.20.2` doesn't). Adopting v-prefix only for `coroot` introduces
  a within-file inconsistency. Three options : (a) v-prefix coroot
  only, document the heterogeneity ; (b) v-prefix all and bump
  `beyla` cosmetically (no functional change on Docker Hub which
  accepts both forms) ; (c) drop v-prefix in `versions:` and
  rewrite at template-render time. To be resolved in `/forge:design`
  ADR-1 ; recommendation lean : (a) keep both forms, documented,
  because changing other components in this change-scope would
  violate the "trio separated" arbitration just ratified.
  **Resolved 2026-05-25 (inverted)** via ADR-B8-COR-001 — the
  verify-then-pin premise of this question was a mis-read ; the
  true GHCR convention is no v-prefix uniformly. See CORRECTION
  NOTICE at top of this proposal + `evidence.md` § 1 for the
  corrected transcripts.
