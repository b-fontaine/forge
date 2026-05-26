# Design: b8-coroot-rehost
<!-- Status: designed -->
<!-- Schema: default -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, Coroot leg) -->

> Read alongside `specs.md` (FR-B8-COR-* / NFR-B8-COR-*) and
> `open-questions.md` (Q-001..Q-004). This document locks the
> implementation strategy and resolves the four open questions via
> ADR-B8-COR-001..004.
>
> **Agents** — Atlas (Infrastructure Architect) primary owner on ADR-001,
> -002, -003 ; Demeter (Data Steward EU) co-owner on ADR-004 ; Eris (Test
> Architect) co-owner on the Testing Strategy section.

---

## Architecture Decisions

### ADR-B8-COR-001 — `versions.*` uniform no-v-prefix (resolves Q-001 ; **inverted 2026-05-25**)

> **Inversion record** : this ADR's first draft (2026-05-24) chose
> "v-prefix coroot only" based on a verify-then-pin transcript that
> turned out to be inverted (background-task outputs mis-labelled
> during `/forge:explore`). At `/forge:implement` Phase 6 the L2
> manifest-pull fixture failed against `ghcr.io/coroot/coroot:v1.20.2`
> ("manifest unknown") and passed against the unprefixed `1.20.2`.
> The Decision section below has been rewritten to match the corrected
> evidence (`.forge/changes/b8-coroot-rehost/evidence.md` § 1).
> The original draft is preserved in git history per Article V audit
> trail.

**Context** : `observability.yaml::versions.coroot` must bump to
`"1.20.2"` (verified pin per `docker manifest inspect
ghcr.io/coroot/coroot:1.20.2` → valid multi-arch OCI index ;
`docker manifest inspect ghcr.io/coroot/coroot:v1.20.2` →
`manifest unknown`). The sibling field `versions.beyla: "2.0.1"`
does not require v-prefix on Docker Hub either. Both registries
accept the unprefixed form for these images. No within-file
heterogeneity exists.

The three options that surfaced during proposal/specs (v-prefix
coroot only / uniform v-prefix / template-render strip-helper) all
addressed a **false dilemma** rooted in the inverted exploration
evidence. Once the evidence is corrected, the decision is trivial.

**Decision** : **Uniform no-v-prefix across `versions.*`**. The
standard ships `versions.coroot: "1.20.2"` (matching Beyla's
existing `versions.beyla: "2.0.1"` shape). A YAML comment block
above `versions:` documents the registry migration (docker.io →
ghcr.io) and the no-v-prefix discovery (with a pointer to
`evidence.md` § 1 for the inverted transcripts).

**Rationale** :

1. **Empirical convention** : `docker manifest inspect
   ghcr.io/coroot/coroot:1.20.2` exits 0 with a valid multi-arch
   OCI index. The opposite (v-prefix) returns `manifest unknown`.
   No interpretation needed.
2. **Trio coupling enforcement (NFR-B8-COR-008)** : the convention
   alignment now happens automatically without any edit to
   `versions.beyla`. `b8-obi-refresh` retains full freedom to
   choose its own pin shape — Coroot has not pre-empted it.
3. **No within-file heterogeneity to document** : the original
   ADR's "asymmetry documentation" rationale evaporates. Adopters
   read a clean uniform list.
4. **Lesson institutionalised** : the L2 manifest-pull fixture
   (FR-B8-COR-072 extended per ADR-B8-COR-003 to assert
   `--config` flag presence) **caught the inversion** before
   archive. This validates the verify-then-pin pattern when
   applied at implementation time, not assumed at exploration
   time. Article III.4 (Anti-Hallucination) discipline upheld.
   A future K.3 amendment or a `standards-lifecycle.md`
   subsection may formalise the "exploration evidence ≠ ratified
   evidence" rule — deferred to a future change.

**Consequences** :

- ✅ Empirically-grounded convention, no interpretation surface.
- ✅ Trio coupling preserved by construction.
- ✅ `versions.*` reads uniformly clean — no inline asymmetry
  comments needed.
- ⚠️ The proposal.md / specs.md / exploration.md narrative still
  carries the original (inverted) "v-prefix mandatory" claim with
  a correction notice. Per Article V the original artifacts are
  preserved (mistake history is informative) ; the corrected ADR
  + open-questions.md resolution + evidence.md are authoritative.
- 📎 No template-render strip-helper introduced. `b8-obi-refresh`
  inherits no GHCR-specific tooling debt.

**Constitution Compliance** : Article III.4 (corrected via
verify-then-pin pass at implementation time ; evidence captured in
`evidence.md` § 1) ; Article V (history preserved : original
inverted narrative kept in proposal/specs/exploration with
correction notice, authoritative correction in design/ADR/
open-questions/evidence/CHANGELOG/REVIEW) ; Article XII (no
constitutional amendment, additive bump).

---

### ADR-B8-COR-002 — No explicit `coroot_registry` frontmatter field (resolves Q-002)

**Context** : Whether `observability.yaml` should gain a
`coroot_registry: "ghcr.io/coroot/coroot"` field — either top-level or
nested under `versions:` — to make the registry signal explicit.

**Decision** : **Option B — do not add an explicit registry field**.

**Rationale** :

1. **Single source of truth** : the registry is already explicit in the
   rendered Kustomize manifest's `image: ghcr.io/coroot/coroot:1.20.2`
   line (`coroot-deployment.yaml.tmpl::spec.template.spec.containers[].image`).
   Adding a duplicate signal in the standard creates a **drift surface**
   between the standard and the template — exactly the failure mode
   `j7-validate-standards-yaml` was created to police.
2. **YAML minimalism principle (T.4 ratification)** : the standards
   v1.0.0 design pattern is "frontmatter minimal, body free-form". A
   registry field tied to a single component (Coroot) does not belong
   at frontmatter level. If a future cross-component pattern emerges
   (e.g. all observability components must declare their registry), a
   constitutional amendment via `b8-signoz-unified` or later is the
   right venue.
3. **No linter rule introduction** : `linter_rule: null` stays. Adding
   the field would invite a new linter rule pair (e.g.
   "image: line must reference the declared registry") which is
   premature.

**Consequences** :

- ✅ Frontmatter shape unchanged ; J.7 invariants stay green ; trio
  coupling NFR-B8-COR-008 honoured.
- ✅ No new linter surface to maintain.
- 📎 If `b8-signoz-unified` or `b8-obi-refresh` later decides a
  registry field is warranted, the precedent for adding it (and the
  linter rule to enforce it) can be set then. The cost of NOT pre-emptively
  adding the field is lower than the cost of pre-emptive addition.

**Constitution Compliance** : Article III.4 (no unsourced field
introduction) ; Article XII (additive bump stays minimal).

---

### ADR-B8-COR-003 — ConfigMap diff verification via CHANGELOG grep + L2 manifest-pull, no kind apply (resolves Q-003)

**Context** : Sixteen minor versions of upstream Coroot evolution lie
between currently-shipped `1.4.4` and target `1.20.2`. Three
options for verifying the templated ConfigMap (`listen` +
`data_dir` + `otel.{grpc,http}.listen` + `integrations.collector_endpoint`)
still deserialises against `1.20.2` :

- **Option A** — Grep CHANGELOG between 1.4.x and 1.20.x for
  ConfigMap field changes ; trust upstream OSS-stability norms.
- **Option B** — Manifest-pull L2 fixture (`docker manifest inspect`
  ghcr.io image, already specified at FR-B8-COR-072).
- **Option C** — Sample-apply on `kind` cluster (most empirical,
  highest CI infrastructure cost).

**Decision** : **Option A + Option B combined ; defer Option C to
`b8-signoz-unified` design**.

**Rationale** :

1. **Surface is small** : the templated ConfigMap consists of exactly
   **5 fields** : `listen`, `data_dir`, `otel.grpc.listen`,
   `otel.http.listen`, `integrations.collector_endpoint`. These are
   Coroot's foundational config — upstream renaming them in a minor
   release would be a Coroot breakage event broadcast widely
   (Coroot CHANGELOG / discussion / blog). Grep + reading CHANGELOG
   entries between v1.5.0 and v1.20.2 covers the surface in
   minutes.
2. **Option B already specified** : FR-B8-COR-072 already requires the
   manifest-pull L2 fixture for existence + multi-arch invariant.
   Adding "image exists AND accepts the same `--config` flag" is a
   1-line incremental check — `docker run --rm
   ghcr.io/coroot/coroot:1.20.2 --help` exit 0, output mentions
   `--config`. Cheap addition.
3. **Option C cost prohibitive in this scope** : kind cluster spin-up
   on CI takes ~30 s + a Kubernetes apply + log inspection = ~2 min
   per run. Article-VIII testing budget for an infra-only template
   change does not justify it. **`b8-signoz-unified` is the natural
   venue for `kind`-based testing** because the 5-service compose
   translation to K8s is much larger and needs that level of
   verification anyway. Deferring the helper here preserves the
   no-new-dep posture (NFR-B8-COR-001) and avoids creeping CI cost.
4. **Demeter / Aegis posture unaffected** : the security-relevant
   surface (capabilities, RBAC, kernel min) lives on the OBI
   DaemonSet, not on Coroot's Deployment. ADR-B8-COR-003 does not
   change `forge.dev/aegis-audit: required` semantics.

**Implementation** :

- During `/forge:implement` Atlas reads the Coroot CHANGELOG entries
  for v1.5.0 → v1.20.2 (GitHub releases) and records findings in a new
  `evidence.md` file in this change directory (mirroring
  `t5-otel-dartastic-realign` evidence-collection pattern).
- The L2 manifest-pull fixture gains a third assertion :
  `docker run --rm ghcr.io/coroot/coroot:1.20.2 --help | grep -q -- --config`
  (proving the `--config=/etc/coroot/config.yaml` arg passed in the
  Deployment template remains valid). Wired into
  `_test_b8cor_l2_001_ghcr_manifest_pullable` extending its body.

**Consequences** :

- ✅ Schema-drift risk mitigated within budget.
- ✅ Zero new CI dependency (no `kind` binary required).
- ✅ Evidence file preserved in audit trail (Article V).
- ⚠️ If CHANGELOG review surfaces a breaking field rename, scope MAY
  expand to update the templated ConfigMap. NFR-B8-COR-006 already
  warns this is possible. In that case `versions.coroot` stays at
  `1.20.2` but the ConfigMap body changes ; `observability.yaml` bump
  becomes `v1.3.0` (still additive, no breaking) — pattern is
  authorised inline.

**Constitution Compliance** : Article I (TDD harness asserts new
fixture pre-implementation) ; Article III.4 (CHANGELOG evidence
recorded, not assumed) ; Article V (audit trail in `evidence.md`).

---

### ADR-B8-COR-004 — T1/T2 OK, T3 candidate-substitution flag in `rationale`, defer new K3-RULE to a future K.3 amendment (resolves Q-004)

**Context** : Coroot Inc is US-incorporated (San Francisco, evidenced
via the GitHub organisation metadata and Coroot's official website
imprint, captured in `evidence.md` during `/forge:implement`).
K3-RULE-001 (T3 forbidden if US-jurisdiction publisher) potentially
applies. Four resolution options :

- **Option A** — T1/T2 OK, T3 candidate-substitution flag without a
  formal Demeter rule extension.
- **Option B** — T1/T2 OK, introduce a new `K3-RULE-EXT-NNN` extending
  K3-RULE-001 with a CE-OSS-no-phone-home carve-out.
- **Option C** — All tiers OK ; no flag.
- **Option D** — All tiers forbidden ; sub-change pivots to
  substitute-candidate exercise.

**Decision** : **Option A — T1/T2 OK posture, T3 candidate-
substitution flag documented in `observability.yaml::rationale`, no
new K.3 rule in this sub-change**.

**Rationale** :

1. **Coroot CE evidence (collected during `/forge:implement`)** :
   Coroot CE under Apache-2.0 (verified : the upstream LICENSE file
   on `coroot/coroot` GitHub repo, captured at SHA-pin in
   `evidence.md`). The CE binary runs entirely on the adopter's
   infrastructure with no upstream phone-home in the OSS path
   (verified : grep of the CE source tree for telemetry endpoints,
   captured in `evidence.md`). The data-plane risk under
   US-jurisdiction reduces to "Coroot Inc maintainership
   responsiveness" — which is a supply-chain risk shared with
   *every* OSS US-jurisdiction publisher.
2. **K3-RULE-001 is a publisher-jurisdiction rule, not a data-residency
   rule** : the current `data-stewardship-rules.md` framing of
   K3-RULE-001 targets services that ingest adopter data into
   US-jurisdiction infrastructure. Coroot CE OSS does not do that.
   Applying K3-RULE-001 strictly to Coroot would also catch Beyla
   (Grafana Labs, US), SigNoz Cloud (US), and a dozen other US-incorp
   OSS publishers — none of which are forbidden in the current
   `observability.yaml`.
3. **Trio-coupling enforcement (NFR-B8-COR-008)** : introducing a new
   K3-RULE-EXT-NNN now would touch `data-stewardship-rules.md` and
   `forbidden-components-rules.md`, both standards owned by K.3 /
   I.3. Their bump cadence is K.3's, not B.8.8's. Cross-territory
   amendments violate the Forge principle of "one change owns one
   namespace bump".
4. **T3 flag pattern is sufficient** : the
   `observability.yaml::rationale` block is already the documented
   home for jurisdiction notes (per `standards-lifecycle.md`).
   Adding a sentence "Coroot CE — Apache-2.0, US-incorporated, no
   upstream phone-home in CE ; T1/T2 OK ; T3 SHOULD flag as
   candidate-substitution pending Demeter pass at deployment time"
   carries the posture forward without standards-pollution.
5. **Demeter audit at deployment time** : T3 adopters running Demeter
   are already required to evidence-collect for every observability
   component (per `data-stewardship-rules.md::Adoption path`). Coroot
   gets flagged there, surfaced as a finding the adopter resolves
   per their compliance posture, exactly as designed.
6. **Future pattern recurrence reserved** : if `b8-signoz-unified`
   (SigNoz Inc US), a hypothetical Grafana Cloud integration, or
   another US-jurisdiction OSS observability publisher arrives, a
   *future* K.3 amendment formalising the CE-OSS-no-phone-home
   carve-out becomes warranted. This change creates the precedent
   ("rationale flag, not new rule") that the future amendment can
   either codify or override.

**Implementation** :

- `observability.yaml::rationale` block updated per FR-B8-COR-038 with
  the T3 candidate-substitution sentence.
- `evidence.md` created with three records :
  1. Coroot Inc US-incorporated (URL + screenshot reference).
  2. Coroot CE Apache-2.0 (LICENSE file SHA pin).
  3. No upstream phone-home in CE (grep result + Coroot docs link).
- No edit to `data-stewardship-rules.md` or
  `forbidden-components-rules.md` in this sub-change.

**Consequences** :

- ✅ Scope contained ; K.3 surface untouched ; trio-coupling preserved.
- ✅ T3 adopters get a clear flag at the right surface
  (`observability.yaml::rationale` + Demeter pass).
- ⚠️ A future Demeter pass at deployment time could still flag Coroot
  CE as forbidden for a specific T3 adopter. Mitigation : that's the
  designed escape valve. The flag does not pre-judge ; the adopter
  decides.
- 📎 The precedent is set : OSS US-jurisdiction publishers with CE-no-
  phone-home get `rationale` flag, not `forbidden:` list entry, unless
  data-plane evidence demands otherwise. This precedent is
  documentation-only (not codified in K.3 yet) and CAN be re-evaluated
  during a future K.3 amendment cycle.

**Constitution Compliance** : Article III.4 (jurisdiction evidence in
`evidence.md`, not assumed) ; Article XII (no standard amendment
beyond `observability.yaml v1.1.0 → v1.2.0` additive) ; K3-RULE-001
re-interpreted in narrow form (publisher-jurisdiction + data-plane,
not publisher-jurisdiction alone) consistent with existing forge
posture toward Beyla (Grafana Labs, US, shipped without flag).

---

## Component Design

The change touches **5 surfaces**, each at a single localised line or
block :

```mermaid
graph TD
    A[".forge/templates/archetypes/full-stack-monorepo/<br/>infra/k8s/base/coroot-deployment.yaml.tmpl<br/>(canonical)"] --> B[cli/assets/.forge/templates/.../coroot-deployment.yaml.tmpl<br/>(bundle mirror — npm run bundle)]
    A -. rendered .-> C[examples/forge-fsm-example/infra/k8s/base/coroot-deployment.yaml<br/>(example rendered)]
    C --> D[cli/assets/examples/forge-fsm-example/.../coroot-deployment.yaml<br/>(bundle example mirror — npm run bundle)]
    A --> E[".forge/standards/observability.yaml<br/>(version + versions.coroot + last_reviewed + rationale)"]
    E --> F[".forge/standards/REVIEW.md<br/>(ledger append-only)"]
    A --> G[".forge/scaffold-snapshots/<br/>full-stack-monorepo/1.0.0.tar.gz<br/>(regenerated via bin/forge-snapshot.sh)"]
    G --> H[cli/assets/.forge/scaffold-snapshots/.../1.0.0.tar.gz<br/>(bundle snapshot mirror)]
```

Per-file edit summary :

| File | Lines touched | What changes |
|---|---|---|
| `…/coroot-deployment.yaml.tmpl` canonical | line 80 + audit-comment block above containers + line 65 annotation | image pin + audit comment + `forge.dev/standard` annotation bump `@1.1.0` → `@1.2.0` |
| `cli/assets/.../coroot-deployment.yaml.tmpl` | same as canonical (byte-identical after bundle) | mirror |
| `examples/.../coroot-deployment.yaml` rendered | same line positions (rendered file) | mirror |
| `cli/assets/examples/.../coroot-deployment.yaml` | same | mirror |
| `observability.yaml` | `version:` + `versions.coroot:` + `last_reviewed:` + `rationale:` + new YAML comment above `versions:` | 5 field edits |
| `REVIEW.md` | append 1 row | ledger entry |
| `1.0.0.tar.gz` snapshot | regenerated | deterministic byte-identical re-emit |

Inline edit recipes (executable during `/forge:implement` after
RED-GREEN harness assertion) :

```bash
# Canonical template — image pin
sed -i.bak 's|image: coroot/coroot:1.4.4|image: ghcr.io/coroot/coroot:1.20.2|' \
    .forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl
sed -i.bak 's|forge.dev/standard: "observability.yaml@1.1.0"|forge.dev/standard: "observability.yaml@1.2.0"|' \
    .forge/templates/archetypes/full-stack-monorepo/infra/k8s/base/coroot-deployment.yaml.tmpl
# Mirrors propagate by re-rendering example + running npm run bundle ;
# direct edit only on the canonical and example.yaml (manual since rendered).

# Standard frontmatter edit (yq preferred ; sed fallback if yq absent)
yq -i '.version = "1.2.0" | .last_reviewed = "2026-05-24" | .versions.coroot = "1.20.2"' \
    .forge/standards/observability.yaml
# `rationale` block update is manual (multi-line, sed-fragile).
```

## Data Flow

N/A — infra-only template refresh. No runtime data flow changes
(Coroot still ingests OTLP gRPC :4317 / HTTP :4318 on the same Service
endpoints ; `integrations.collector_endpoint` unchanged ;
`forge.dev/aegis-audit: required` annotation remains on OBI DaemonSet
not on Coroot Deployment).

## Testing Strategy

Owner : **Eris** (Test Architect). Mirrors the `b1-1-dev-up-matrix-fixes`
harness pattern.

### L1 (hermetic grep-based, MUST run in CI on every PR)

13 anchors per FR-B8-COR-071. Wall-clock budget ≤ 2 s (NFR-B8-COR-002).
Tested in order :

1. Canonical pin presence (FR-B8-COR-001 + -003).
2. No legacy `coroot/coroot:1.x` pin remaining (FR-B8-COR-001).
3. Audit comment present (FR-B8-COR-008).
4. `cli/assets/` template byte-identity (FR-B8-COR-004).
5. Example rendered pin (FR-B8-COR-005).
6. `cli/assets/examples/` byte-identity (FR-B8-COR-006).
7. Exactly 4 paths (FR-B8-COR-007).
8. Standard `version: 1.2.0` (FR-B8-COR-030).
9. Standard `versions.coroot: v1.20.2` (FR-B8-COR-031).
10. Standard `last_reviewed: 2026-05-24` (FR-B8-COR-034).
11. REVIEW.md ledger row (FR-B8-COR-050).
12. `validate-standards-yaml.sh` exit 0 (FR-B8-COR-035).
13. CHANGELOG entry (FR-B8-COR-120).

### L2 (opt-in, gated on `FORGE_B8_COROOT_DOCKER=1` + `command -v docker`)

Per ADR-B8-COR-003, two assertions :

1. `_test_b8cor_l2_001_ghcr_manifest_pullable` — extended with the
   `--help` `--config`-flag check :
   ```bash
   docker manifest inspect ghcr.io/coroot/coroot:1.20.2 \
       | grep -q '"architecture":"amd64"' \
       && docker manifest inspect ghcr.io/coroot/coroot:1.20.2 \
              | grep -q '"architecture":"arm64"' \
       && docker run --rm ghcr.io/coroot/coroot:1.20.2 --help 2>&1 \
              | grep -q -- '--config'
   ```
2. `_test_b8cor_l2_002_old_pin_denied` — verify-then-pin invariant
   (FR-B8-COR-073). WARN-only on flip (per ADR-B8-COR-003 footnote :
   if docker.io public access is re-opened, future change re-evaluates
   the rationale ; harness surfaces as WARN-not-FAIL).

### Evidence collection (Article V audit trail)

A new file `.forge/changes/b8-coroot-rehost/evidence.md` is created
during `/forge:implement`, capturing :

1. Verify-then-pin transcripts (5 `docker manifest inspect` results,
   2026-05-24).
2. Coroot CHANGELOG review v1.5.0 → v1.20.2 (per ADR-B8-COR-003).
3. Demeter jurisdiction evidence (per ADR-B8-COR-004) :
   - Coroot Inc US-incorporated (URL pin).
   - Coroot CE Apache-2.0 (LICENSE SHA pin).
   - No upstream phone-home in CE (grep result).

### BDD scenarios (specs.md `BDD Scenarios`)

Two L2 scenarios already documented in Gherkin (specs.md). No
additional BDD in design.

### Unit / Widget / Integration

N/A — no Rust crate, no Flutter widget, no Dart unit ; this is
infra-only.

## Standards Applied

- **`global/observability.yaml`** — v1.1.0 → **v1.2.0 additive** :
  this change owns the bump.
- **`global/standards-lifecycle.md`** v1.1.0 — applied : REVIEW.md
  ledger append-only entry, 12-month loose cadence preserved.
- **`global/data-stewardship-rules.md`** — applied via ADR-B8-COR-004
  : K3-RULE-001 narrow interpretation (no edit to the rule itself).
- **`global/forbidden-components-rules.md`** — applied : Coroot not
  added to `forbidden:` list (T3 candidate-substitution flag is in
  `observability.yaml::rationale`, not in this standard).
- **`global/compliance-tiers.md`** v1.0.0 — applied implicitly : T1/T2
  CE-OK posture, T3 flag at deployment time per Demeter pass.
- **`global/sbom-policy.md`** — applied : the new pin
  (`ghcr.io/coroot/coroot:1.20.2`) MUST appear in the next CycloneDX
  SBOM emission via `bin/forge-sbom.sh`. No code change to forge-sbom
  here ; the SBOM picks it up via the rendered manifest.
- **`global/upgrade-policy.md`** — applied : `forge upgrade` 3-way
  merge handles the rehost as a single-line content edit in a
  framework-owned path (`infra/k8s/base/coroot-deployment.yaml`). No
  `[NEEDS MIGRATION:]` marker required ; the upgrade succeeds
  non-destructively.

---

## Constitutional Compliance Gate

Pre-implementation checklist (re-verified at the end of design phase,
2026-05-24) :

| Article | Compliance check | Status |
|---|---|---|
| I — TDD | Harness `b8-coroot.test.sh` exists pre-implementation, asserts RED, only then GREEN via edits | ✅ Plan locked, no implementation prior |
| II — BDD | N/A (no user-facing feature) — documented anyway in specs.md | ✅ |
| III — Specs Before Code | proposal.md ✅ specs.md ✅ design.md (this) ✅ — tasks.md next via `/forge:plan` | ✅ |
| III.4 — Anti-Hallucination | All 14 surfaces sourced in specs.md ; ADR-001..004 evidence in `evidence.md` (`/forge:implement` phase) | ✅ |
| V — Audit trail | parent_audit_items + research note cross-ref + ADRs immutable + REVIEW append-only | ✅ |
| VIII — Infra excellence | Observability mandate maintained ; coroot pullability restored | ✅ |
| XII — Governance | observability.yaml v1.1.0 → v1.2.0 additive ; REVIEW append ; no constitution amendment | ✅ |

No `[CONSTITUTION VIOLATION:]` flag raised. Design is ratified.

---

*Next : `/forge:plan b8-coroot-rehost`.*
