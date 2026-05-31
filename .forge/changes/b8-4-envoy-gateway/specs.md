# Specifications: b8-4-envoy-gateway

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.8.4 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0, Envoy Gateway templates) -->

**Namespace** : `FR-B84-*` / `NFR-B84-*` / `ADR-B84-*`.
**Constitution** : v1.1.0, unchanged (no amendment — see proposal "Constitution
Compliance" re Article VIII.1). This change is **propose + specify only**. It
authors the requirements + ADRs for the `full-stack-monorepo / 2.0.0` **Envoy
Gateway** template brick (B.8.4) — the first real 2.0.0 template brick and the
first consumer of the B.8.3 candidate schema. It ships **no template, no
concrete version pin, and no standard file** — the templates, the gateway pin,
and the gateway standard are delivered in the impl phase, where pins are
**verify-then-pin** live on the registry.
**Governing articles** : III.1/III.2 (specs before code), III.4 (Anti-
Hallucination — never invent versions/APIs), IV (delta-based: the 2.0.0 tree is
additive, the flat 1.0.0 tree and `infra/kong/` are untouched), VIII.1 (Kong
SHALL — in force; Envoy is additive, no amendment yet), VIII.5 (IaC), X (J.7
standard contract).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §4 (Module B.8), §4.1 (additive-first: "Ajouter Envoy Gateway en parallèle de Kong (canary par route)"), §4.2 B.8.4 ("Templates Helm Envoy Gateway sous `templates/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/` avec `Gateway`, `HTTPRoute`, `BackendTLSPolicy` Gateway API natifs. Helm chart Atlas-fourni. Effort: M."), §13 caveat 2 ("garder gRPC-Web standard via Envoy Gateway") |
| **Candidate schema (observed)** | `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (B.8.3, candidate, `scaffoldable: false`) — component `envoy-gateway` { role: api-gateway, replaces: kong, delivered_by: B.8.4, pin_source: B.8.4 }; migration_delta { from: kong-gateway, to: envoy-gateway, brick: B.8.4, strategy: additive-first }; bump_at: B.8.14 |
| **1.0.0 gateway (observed)** | `.forge/templates/archetypes/full-stack-monorepo/infra/kong/kong.yml.example.tmpl` (DB-less declarative, upstream `http://fsm-backend:8080`, cites Article VIII.1) + markdown standard `.forge/standards/infra/kong.md` (plugins, decK, grpc-gateway transcoding). **No `*.yaml` gateway pin standard exists.** Baseline gateway = `kong:3.6` (docs/B8-BASELINE.md §1) |
| **1.0.0 template layout (observed)** | FLAT under `.forge/templates/archetypes/full-stack-monorepo/` — NO version subdir. K8s base = `infra/k8s/base/{deployment,service,serviceaccount,ingress,kustomization}.yaml.tmpl` + `obi-daemonset` + `coroot-deployment`; overlays `infra/k8s/overlays/{dev,staging,prod}/`. Kustomize-based, controller-agnostic (`ingress.yaml.tmpl` keeps IngressClass/annotations in overlays). Standards `infra/kubernetes.md`, `infra/k8s-overlays.md` |
| **Standard frontmatter contract (observed)** | J.7-validated `.forge/standards/*.yaml`: `version` / `last_reviewed` / `expires_at` / `exception_constitutional` / `linter_rule` / `enforcement{ci_blocking,pre_commit_hook}` / `forbidden` / `rationale` + optional `versions:` map + `pin_review_cadence:` (ISO 8601). Precedent: `observability.yaml` v2.1.0, `transport.yaml` v1.2.0. Index `.forge/standards/index.yml` + ledger `.forge/standards/REVIEW.md` |
| **Constitution (observed)** | v1.1.0 §VIII.1 (Kong SHALL — IN FORCE); 2.0.0.yaml header records VIII.1 binding until B.8.14 amends via GOVERNANCE.md process |
| **Predecessor / dependency** | B.8.3 (`b8-3-schema-candidate`, archived 2026-05-30 — 2.0.0 candidate schema; ADR-B8-3-001 versioned-sibling precedent; ADR-B8-3-002 pins-vs-reference; `pin_source: B.8.4` for the gateway) |
| **Downstream consuming this** | B.8.6 (Connect transport — couples to transcoding Q-004), B.8.10 (migration script — canary cutover), B.8.12 (zero-regression gate — asserts convergence to the Envoy gateway target), B.8.14 (Kong removal + 1.0.0→2.0.0 bump) |
| **External research** | Context7: `/envoyproxy/gateway` (Envoy Gateway Helm/CRDs) + `/kubernetes-sigs/gateway-api` (Gateway API resource API versions). Evidence below. Concrete pins **verify-then-pin at implement**. |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Versioned 2.0.0 template tree & additive coexistence (FR-B84-001 → 009)

##### FR-B84-001 — new versioned 2.0.0 template root
The Envoy Gateway templates, when authored in the impl phase, MUST live in a
NEW versioned subtree rooted at
`.forge/templates/archetypes/full-stack-monorepo/2.0.0/`, with the Envoy
resources under `.../2.0.0/infra/k8s/envoy-gateway/` (plan §4.2 B.8.4). This
mirrors the B.8.3 versioned-sibling precedent (`2.0.0.yaml` beside the flat
`schema.yaml`). The exact root + scaffolder/snapshot awareness is ADR-B84-001.

##### FR-B84-002 — flat 1.0.0 tree byte-untouched
The change (and the impl step) MUST NOT modify any existing file under the flat
`.forge/templates/archetypes/full-stack-monorepo/` 1.0.0 tree, and MUST NOT
modify `infra/kong/kong.yml.example.tmpl`. `git diff --name-only` MUST show the
flat 1.0.0 tree (incl. `infra/kong/`, `infra/k8s/base/`, overlays) untouched —
only NEW paths under `.../2.0.0/...` are added.

##### FR-B84-003 — additive-first, Kong NOT removed
Per plan §4.1 (additive-first), Envoy MUST be added **in parallel** with Kong.
B.8.4 MUST NOT remove or deprecate the Kong example, MUST NOT alter the 1.0.0
gateway (which remains Kong, `kong:3.6` baseline), and MUST NOT amend or
weaken Constitution Article VIII.1. Kong removal is B.8.14.

##### FR-B84-004 — non-scaffoldable by default (candidate tree)
The 2.0.0 Envoy templates MUST inherit the candidate's `scaffoldable: false`
posture (2.0.0.yaml, ADR-B8-3-003/005): `forge init --archetype
full-stack-monorepo` MUST continue to scaffold the 1.0.0 (Kong) tree and MUST
NOT scaffold the 2.0.0 Envoy tree by default. The Envoy tree is an additive
on-disk asset gating B.8.10/B.8.12/B.8.14 until B.8.14 promotes 2.0.0 to
`stable`. Whether enforcing this requires scaffolder/template-root rewiring is
flagged in ADR-B84-001 as a possible separate concern (NOT done in B.8.4).

#### Cluster 2 — Gateway API native resources (FR-B84-010 → 019)

##### FR-B84-010 — GatewayClass bound to the Envoy Gateway controller
The brick MUST provide a `GatewayClass` whose `spec.controllerName` is the Envoy
Gateway controller identifier, at the `gateway.networking.k8s.io` API version of
the shipped Gateway API CRD bundle (Context7: `Gateway`/`GatewayClass`/
`HTTPRoute` are GA at `…/v1` since the Gateway API v1.0 release). The concrete
`controllerName` string + API version are sourced from the shipped Envoy Gateway
release (verify-then-pin), NOT invented (Q-005).

##### FR-B84-011 — Gateway with listener(s)
The brick MUST provide a `Gateway` resource referencing the `GatewayClass`
(FR-B84-010) with at least one listener (e.g. HTTP/HTTPS) exposing the backend
surface. Listener protocol/port/TLS config MUST be templated for per-environment
override consistent with the 1.0.0 overlay convention
(`infra/k8s/overlays/{dev,staging,prod}/`) where applicable (ADR-B84-003).

##### FR-B84-012 — HTTPRoute(s) to the backend Service
The brick MUST provide one or more `HTTPRoute` resources that `parentRefs` the
`Gateway` (FR-B84-011) and `backendRefs` the backend Service (the same
`fsm-backend` upstream the Kong example targets), at the GA `…/v1` API version.
Routing rules (path matches, hostnames) MUST be templated. This is the
route-level surface that enables canary-by-route additive migration (§4.1).

##### FR-B84-013 — BackendTLSPolicy for upstream TLS
The brick MUST provide a `BackendTLSPolicy` configuring TLS validation of the
upstream backend connection (`spec.validation` / `targetRefs` shape per the
shipped CRD bundle). **The `apiVersion` of `BackendTLSPolicy` MUST match the
shipped Gateway API CRD bundle** — Context7 shows it has moved across
`v1beta1` → `v1alpha3` → `v1` (GA as of Gateway API v1.5.1); B.8.4 MUST NOT
hard-code one of these speculatively (Q-005, verify-then-pin). If the shipped
bundle does not GA `BackendTLSPolicy`, the impl MUST surface
`[NEEDS CLARIFICATION]` rather than guess the channel/version.

##### FR-B84-014 — resources are Gateway-API-native (no Ingress, no Kong CRDs)
The Envoy data-plane resources MUST be expressed purely with
`gateway.networking.k8s.io` Gateway API types (`GatewayClass`/`Gateway`/
`HTTPRoute`/`BackendTLSPolicy`, plus `ReferenceGrant` if cross-namespace refs
are needed). They MUST NOT use the legacy `networking.k8s.io/v1 Ingress` (the
1.0.0 `ingress.yaml.tmpl` stays in the 1.0.0 tree) and MUST NOT introduce
Kong-specific CRDs.

#### Cluster 3 — Envoy Gateway install / delivery model (FR-B84-020 → 029)

##### FR-B84-020 — Envoy Gateway control-plane install expressed
The brick MUST express the installation of the Envoy Gateway control plane
(controller + its required Gateway API CRDs). Per plan §4.2 ("Helm chart
Atlas-fourni"), the install SHOULD use the official Helm chart distributed as an
OCI artifact at `oci://docker.io/envoyproxy/gateway-helm` (Context7 evidence
below). The chart installs Envoy Gateway and its required CRDs.

##### FR-B84-021 — delivery model (Helm vs kustomize) decided, not assumed
The brick MUST adopt a delivery model reconciling "Helm chart Atlas-fourni"
(plan) with the kustomize-based, controller-agnostic 1.0.0 `k8s/base/`
convention (ADR-B84-003). Leaning: Helm for the **control-plane install**
(`gateway-helm`), Gateway-API-native **manifests under kustomize** for the
**data-plane** resources (`GatewayClass`/`Gateway`/`HTTPRoute`/
`BackendTLSPolicy`). The chosen model MUST be internally consistent (a single
`kustomization` or chart references all data-plane resources) and documented.

##### FR-B84-022 — pins sourced from the gateway pin, not inlined ad hoc
The Envoy Gateway Helm chart version and the Gateway API CRD bundle version used
by the install MUST be sourced from the gateway pin created by this brick
(`pin_source: B.8.4`, FR-B84-030), not scattered as unmanaged literals across
templates.

#### Cluster 4 — Gateway pin source (`pin_source: B.8.4`) (FR-B84-030 → 039)

##### FR-B84-030 — create the gateway version pin + its standard source
B.8.4 MUST create the gateway version pin that does not exist today (no `*.yaml`
standard pins a gateway — only markdown `infra/kong.md`). Per ADR-B84-002 the
leaning is a NEW `.forge/standards/infra/gateway.yaml` holding (a) the Envoy
Gateway Helm chart version and (b) the Gateway API CRD bundle version, under the
J.7 frontmatter contract. The pin source MUST be unambiguous and machine-
checkable.

##### FR-B84-031 — new gateway standard satisfies the J.7 contract
If a NEW `infra/gateway.yaml` standard is created (ADR-B84-002 lean), it MUST
carry the J.7-required frontmatter (`version`, `last_reviewed`, `expires_at`,
`exception_constitutional`, `linter_rule`, `enforcement{ci_blocking,
pre_commit_hook}`, `forbidden`, `rationale`), a `versions:` map for the pins,
and a `pin_review_cadence:` (ISO 8601, per the b8-signoz precedent). It MUST be
registered in `.forge/standards/index.yml` (triggers) and birth-entried in
`.forge/standards/REVIEW.md` (`validate-standards-yaml.sh` FR-J7-023/030/050).

##### FR-B84-032 — wire the candidate schema's standard ref (candidate edit allowed)
Per ADR-B84-002 (lean), the 2.0.0.yaml `envoy-gateway` component SHOULD gain a
`standard:` ref pointing at the new gateway standard (e.g.
`standard: gateway.yaml`), resolving its current `pin_source: B.8.4` /
no-`standard:` gap. Editing `2.0.0.yaml` is **permitted** here because it is the
**candidate** (not the frozen 1.0.0 `schema.yaml`); this MUST be explicitly
confirmed + ADR'd (ADR-B84-002). The frozen `schema.yaml` MUST stay untouched.

##### FR-B84-033 — concrete pins are verify-then-pin, never fabricated
The concrete Envoy Gateway Helm chart version and the Gateway API CRD-bundle API
versions MUST be **verified live** at `/forge:implement` (e.g.
`helm show chart oci://docker.io/envoyproxy/gateway-helm` / registry inspect +
`kubectl explain` / CRD `bundle-version` annotation) **before** being written to
the standard or templates (kong/b8-coroot verify-then-pin lesson). This spec
MUST NOT, and the design MUST NOT, assert a concrete version as registry-
verified. Where uncertain, `[NEEDS CLARIFICATION]` is required (Q-005).

#### Cluster 5 — Transport coexistence with Connect / Kong (FR-B84-040 → 049)

##### FR-B84-040 — coexistence contract for B.8.12
The brick MUST document the additive-first coexistence contract so B.8.12's
zero-regression gate has a canonical target: Envoy `HTTPRoute`s and the Kong
example both route to `fsm-backend`, enabling canary-by-route (§4.1); neither
removes the other; cutover + Kong removal are B.8.10 / B.8.14.

##### FR-B84-041 — transcoding parity decision recorded (couples to B.8.6)
The brick MUST record the REST↔gRPC handling decision (ADR-B84-005): under 2.0.0
the transport target is Connect-RPC (`transport.yaml` v1.2.0, B.8.6), and §13
caveat 2 names gRPC-Web via Envoy Gateway as a fallback. Whether B.8.4's
`HTTPRoute`s assume Connect/gRPC-Web pass-through (no gateway-side transcoding,
unlike Kong's `grpc-gateway` plugin) or must replicate transcoding is decided at
design, not guessed — it couples to B.8.6 (Q-004).

### Non-Functional Requirements

##### NFR-B84-001 — anti-hallucination grounding (versions & APIs)
Every gateway/template/standard claim in the specs MUST be re-read from a live
file (2.0.0.yaml, kong.yml.example.tmpl, kong.md, k8s base templates, the J.7
standard frontmatter contract) or from Context7 (Envoy Gateway + Gateway API).
The plan-vs-live path contradiction (versioned 2.0.0 tree vs flat 1.0.0) and the
`BackendTLSPolicy` API-version drift MUST be recorded, not normalized. No
concrete external version is asserted as verified (Article III.4).

##### NFR-B84-002 — zero mutation in B.8.4 propose/specify
This change MUST NOT edit any `.forge/standards/**`, `.forge/templates/**`,
`.forge/schemas/**`, or Constitution file, and MUST NOT bump any version. It only
authors `b8-4-envoy-gateway/{.forge.yaml, proposal.md, specs.md,
open-questions.md}`.

##### NFR-B84-003 — frozen 1.0.0 byte-identity preserved
`schema.yaml`, the flat 1.0.0 template tree (incl. `infra/kong/` and
`infra/k8s/base/`), and `full-stack-monorepo/1.0.0.tar.gz` MUST be byte-unchanged
by this change AND by the downstream impl (which adds only NEW `.../2.0.0/...`
paths). Respects B.8.2 freeze + its sha256 guard.

##### NFR-B84-004 — backward compatibility of existing gates
`validate-foundations.sh` (FR-GL-001), `verify.sh`, and `constitution-linter.sh`
MUST stay GREEN. They read the flat `schema.yaml` (untouched) and the flat 1.0.0
tree (untouched). Adding the `.../2.0.0/...` template subtree + a new
`infra/gateway.yaml` standard MUST NOT, by itself, break these gates; a new
standard MUST pass `validate-standards-yaml.sh` (J.7).

##### NFR-B84-005 — verify-then-pin at implement (no premature pins)
The specs + design MUST treat the Envoy Gateway Helm chart version and the
Gateway API CRD-bundle API versions as **deferred** to a live verification step
at `/forge:implement`. A concrete pin written before live verification is a
constitutional anti-hallucination failure (Article III.4; kong/b8-coroot
lesson). Until then the components + API shapes are identified by name/shape only.

##### NFR-B84-006 — the brick gates downstream
The specs MUST establish that B.8.10 (migration/canary), B.8.12 (zero-regression
convergence), and B.8.14 (Kong removal + bump) build on the Envoy gateway target
declared here, and that B.8.6 (Connect transport) coexists per Q-004.
(Traceability requirement; no runtime artifact in B.8.4 propose/specify.)

## Architecture Decision Records (seeds — finalized at /forge:design)

- **ADR-B84-001 — versioned 2.0.0 template tree.** Plan §4.2 names
  `templates/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`; live 1.0.0 is
  FLAT. **Lean:** new `.../full-stack-monorepo/2.0.0/` additive subtree
  (mirrors `2.0.0.yaml` sibling), Envoy under `2.0.0/infra/k8s/envoy-gateway/`;
  flat 1.0.0 untouched. Scaffolder/snapshot awareness of the versioned root =
  possible separate concern (parallels B.8.3.b). Resolved at design.
- **ADR-B84-002 — gateway pin source (`pin_source: B.8.4`).** **Lean:** NEW
  `.forge/standards/infra/gateway.yaml` (J.7-compliant) pins Envoy Gateway Helm
  chart + Gateway API CRD bundle; register in `index.yml` + `REVIEW.md`; add
  `standard: gateway.yaml` to the 2.0.0.yaml envoy component (candidate edit —
  permitted, must be confirmed). Alt (b): keep `pin_source`, pin in
  chart/values only. Resolved at design.
- **ADR-B84-003 — Helm chart vs raw kustomize.** **Lean:** Helm
  (`oci://docker.io/envoyproxy/gateway-helm`) for the control-plane install;
  Gateway-API-native manifests under kustomize for the data-plane resources,
  consistent with 1.0.0 `k8s/base/` + overlays. Exact split decided at design.
- **ADR-B84-004 — additive-first wiring (Envoy ∥ Kong).** **Lean:** Envoy
  resources alongside the Kong example, both → `fsm-backend`, canary-by-route
  (§4.1); B.8.4 removes nothing; cutover/removal = B.8.10/B.8.14.
- **ADR-B84-005 — REST↔gRPC transcoding parity (open).** Couples to B.8.6
  (Connect-RPC). **Lean:** Connect/gRPC-Web pass-through (no gateway-side
  transcoding); gRPC-Web fallback per §13 caveat 2. Genuinely undecided —
  resolved at design with the B.8.6 transport decision, not guessed.

## Context7 Evidence (external research, 2026-05-31 — Article III.4)

> Components + API shapes IDENTIFIED here; concrete version pins **deferred to
> verify-then-pin at `/forge:implement`** (NFR-B84-005). Doc-snippet versions
> below are rendered as placeholders/release-line markers, NOT registry-verified
> pins.

**Envoy Gateway** — Context7 lib `/envoyproxy/gateway`:
- Helm chart is an **OCI artifact** at `oci://docker.io/envoyproxy/gateway-helm`.
  Install: `helm install eg oci://docker.io/envoyproxy/gateway-helm --version
  <ver> -n envoy-gateway-system --create-namespace` (also `--set
  deployment.replicas=N`, Flux `OCIRepository` `url: oci://docker.io/envoyproxy/
  gateway-helm`, Argo `repoURL: docker.io/envoyproxy` `chart: gateway-helm`).
  The chart installs Envoy Gateway **and its required Gateway API CRDs**.
- Current docs tree = **v1.8 release line** (doc source URLs
  `.../en/v1.8/install/install-helm.md`). Chart version rendered as
  `{{< helm-version >}}` placeholder in docs → **concrete pin NOT verified here**
  (verify-then-pin at impl).

**Gateway API** — Context7 lib `/kubernetes-sigs/gateway-api`:
- Latest supported API version is **`v1`**, released by **v1.5.1** of the
  project (README "Status"): GA-level support for `v1.GatewayClass`,
  `v1.Gateway`, `v1.ListenerSet`, `v1.HTTPRoute`, `v1.GRPCRoute`, `v1.TLSRoute`,
  **`v1.BackendTLSPolicy`**, `v1.ReferenceGrant`.
- `Gateway` / `GatewayClass` / `HTTPRoute` graduated to
  `gateway.networking.k8s.io/v1` in the **v1.0 release** (Standard channel since
  v0.5.0 for HTTPRoute). `ReferenceGrant` stays beta (migrating upstream).
- **`BackendTLSPolicy` API-version drift (the load-bearing uncertainty):**
  Context7 returns three shapes across doc generations —
  `gateway.networking.k8s.io/v1beta1` (older guide, `spec.targetRef` + `tls`),
  and `gateway.networking.k8s.io/v1` (newer guide, `spec.targetRefs` +
  `validation.wellKnownCACertificates: System`); `v1alpha3` existed at
  intermediate releases. **GA `v1` is current as of v1.5.1.** The exact
  `apiVersion` to ship is keyed to the **concrete CRD bundle that the pinned
  Envoy Gateway release vendors** → `[NEEDS CLARIFICATION]` (Q-005), resolved by
  live `kubectl explain` / CRD `gateway.networking.k8s.io/bundle-version`
  annotation at impl.
- Release channels: `Standard` (GA/stable, recommended) vs `Experimental`
  (alpha). CRDs annotate `gateway.networking.k8s.io/channel: standard|
  experimental` + `bundle-version`. The brick MUST target the **Standard
  channel** for GA resources (the impl verifies which channel the shipped bundle
  graduates `BackendTLSPolicy` in).

**Deferred to verify-then-pin at implement (Q-005 / NFR-B84-005):**
1. Envoy Gateway Helm chart concrete version (`oci://docker.io/envoyproxy/
   gateway-helm --version <X>`) — verified via registry/`helm show chart`.
2. Gateway API CRD bundle version vendored by that Envoy Gateway release +
   the `bundle-version` / `channel` annotations.
3. The exact `apiVersion` of `BackendTLSPolicy` (v1beta1 / v1alpha3 / v1) in
   that bundle, and whether it is in the Standard or Experimental channel.
4. The Envoy Gateway `GatewayClass.spec.controllerName` string for the pinned
   release.

## BDD Acceptance Criteria

```gherkin
Feature: Envoy Gateway templates declared additively for the 2.0.0 candidate
  As a Forge B.8 migration architect
  I want the Envoy Gateway templates authored against the 2.0.0 candidate schema
  So that the flagship gateway can move Kong -> Envoy additively, without
  disturbing the frozen 1.0.0 stack or the in-force Article VIII.1

  Scenario: The Envoy gateway brick is specified without disturbing the frozen 1.0.0 flagship
    Given the 2.0.0 candidate schema declaring envoy-gateway (replaces: kong, delivered_by/pin_source B.8.4)
    And the flat 1.0.0 template tree with infra/kong/kong.yml.example.tmpl and infra/k8s/base/ (Kong, kustomize)
    And Constitution Article VIII.1 (Kong SHALL) in force until B.8.14
    When the Envoy Gateway brick is authored from these specs
    Then the Envoy templates live under templates/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/ as a NEW additive subtree
    And the resources are Gateway API native: GatewayClass, Gateway, HTTPRoute, BackendTLSPolicy (no Ingress, no Kong CRDs)
    And the Envoy Gateway control plane installs via the Helm chart oci://docker.io/envoyproxy/gateway-helm
    And the concrete Envoy Gateway chart version and the BackendTLSPolicy apiVersion are verified live at /forge:implement, never fabricated
    And the gateway version pin is created as the pin_source:B.8.4 contract (new infra/gateway.yaml standard, J.7-compliant)
    And the flat 1.0.0 tree, infra/kong/, schema.yaml, and 1.0.0.tar.gz remain byte-identical
    And full-stack-monorepo still scaffolds as 1.0.0/Kong by default (the 2.0.0 Envoy tree is scaffoldable:false, additive, parallel to Kong)
    And Article VIII.1 is NOT amended (Envoy is additive; the amendment, if any, lands at B.8.14)
```

## Anti-Hallucination Pass

- **Plan path vs live layout** — plan §4.2 names a versioned
  `templates/full-stack-monorepo/2.0.0/...` tree; the live 1.0.0 templates are
  FLAT (no version subdir). Contradiction RECORDED → Q-001 / ADR-B84-001, not
  silently normalized. Mirrors B.8.3 ADR-B8-3-001.
- **Gateway pin gap** — confirmed by re-reading: no `*.yaml` standard pins a
  gateway today; only markdown `infra/kong.md` + the Kong example template. The
  Envoy pin is therefore CREATED here (`pin_source: B.8.4`), not assumed to
  exist (Q-002 / ADR-B84-002).
- **Envoy Gateway / Gateway API versions** — sourced from Context7
  (`/envoyproxy/gateway`, `/kubernetes-sigs/gateway-api`), NOT training data.
  The Helm coordinates (`oci://docker.io/envoyproxy/gateway-helm`) and the
  Gateway-API resource shapes are recorded; the **concrete chart version + the
  `BackendTLSPolicy` apiVersion are deferred to verify-then-pin at implement**
  (NFR-B84-005). The `BackendTLSPolicy` v1beta1/v1alpha3/v1 drift is flagged
  `[NEEDS CLARIFICATION]` (Q-005), not guessed (kong/b8-coroot lesson:
  verify-then-pin runs LIVE at `/forge:implement`).
- **Article VIII.1 framing** — Kong SHALL is IN FORCE; B.8.4 ships Envoy
  ADDITIVELY (parallel, §4.1) inside the `scaffoldable: false` candidate tree,
  so it neither violates VIII.1 nor requires the amendment yet. The amendment is
  B.8.14. Stated explicitly, not assumed away.
- **Temporal / DBOS / Connect / Zitadel** — out of scope for B.8.4; not
  conflated with the gateway brick.
- **Independent review (REQUIRED before design)** — these propose + specify
  artifacts MUST pass an INDEPENDENT reviewer (not the author) before
  `/forge:design`. Not self-approved here.

## Open Questions

Tracked in `open-questions.md`: Q-001 (versioned 2.0.0 template tree path →
ADR-B84-001, open), Q-002 (gateway pin source: new `infra/gateway.yaml` +
candidate `standard:` ref → ADR-B84-002, open), Q-003 (Helm vs kustomize
delivery → ADR-B84-003, open), Q-004 (REST↔gRPC transcoding parity, couples to
B.8.6 → ADR-B84-005, open), Q-005 (concrete Envoy Gateway chart version +
`Gateway`/`HTTPRoute`/`BackendTLSPolicy` API versions — verify-then-pin at
implement, open).
