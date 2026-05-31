# Spec: b8-envoy-gateway

<!-- Audit: B.8.4 (b8-4-envoy-gateway) -->
<!-- Source change : `.forge/changes/b8-4-envoy-gateway/` (delta specs.md authoritative). -->

**Namespace** : `FR-B84-*` / `NFR-B84-*` / `ADR-B84-*`.
**Constitution** : v1.1.0, unchanged (no amendment — Article VIII.1 Kong SHALL in force;
Envoy is additive, no amendment yet). This change is **propose + specify + design + implement**.
It delivers the first 2.0.0 template brick — Envoy Gateway (Gateway API native) additive in
parallel with Kong. Root standard `.forge/standards/gateway.yaml` created; verify-then-pin
done (Envoy Gateway Helm chart v1.8.0 / Gateway API CRD bundle v1.5.1 / all GA `v1`).
**Governing articles** : I (TDD RED-first for the harness), III.1/III.2 (specs before code),
III.4 (Anti-Hallucination — verify-then-pin, never fabricate versions), IV (delta-based:
the 2.0.0 tree is additive, the flat 1.0.0 tree and `infra/kong/` are untouched), VIII.1
(Kong SHALL — in force; Envoy is additive; VIII.1 amendment deferred to B.8.14), VIII.5
(IaC), X (J.7 standard contract).

## Overview

This brick delivers the first real `full-stack-monorepo / 2.0.0` template content: an
Envoy Gateway (Gateway API native) additive layer running in parallel with the existing
Kong gateway. Templates live under `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`
(`GatewayClass`, `Gateway`, `HTTPRoute`, `BackendTLSPolicy`, `kustomization.yaml`, `README`
install doc). A new root standard `.forge/standards/gateway.yaml` (J.7-compliant) pins the
Envoy Gateway Helm chart (`oci://docker.io/envoyproxy/gateway-helm`) and the Gateway API
CRD bundle, resolving the `pin_source: B.8.4` declared in `2.0.0.yaml`. Concrete versions
are **verify-then-pin done live**: chart v1.8.0, bundle v1.5.1, `BackendTLSPolicy` GA
`gateway.networking.k8s.io/v1` Standard channel. `2.0.0.yaml` envoy component updated:
`pin_source: B.8.4` → `standard: gateway.yaml`. The flat 1.0.0 tree, `infra/kong/
kong.yml.example.tmpl`, `schema.yaml`, and `1.0.0.tar.gz` are byte-unchanged.
`b8-4.test.sh` 12 L1 hermetic; independent review APPROVE; archived 2026-05-31.

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Versioned 2.0.0 template tree & additive coexistence (FR-B84-001 → 004)

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

#### Cluster 2 — Gateway API native resources (FR-B84-010 → 014)

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

#### Cluster 3 — Envoy Gateway install / delivery model (FR-B84-020 → 022)

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

#### Cluster 4 — Gateway pin source (`pin_source: B.8.4`) (FR-B84-030 → 033)

##### FR-B84-030 — create the gateway version pin + its standard source
B.8.4 MUST create the gateway version pin that does not exist today (no `*.yaml`
standard pins a gateway — only markdown `infra/kong.md`). Per ADR-B84-002 the
leaning is a NEW `.forge/standards/gateway.yaml` holding (a) the Envoy
Gateway Helm chart version and (b) the Gateway API CRD bundle version, under the
J.7 frontmatter contract. The pin source MUST be unambiguous and machine-
checkable.

##### FR-B84-031 — new gateway standard satisfies the J.7 contract
If a NEW `gateway.yaml` standard is created (ADR-B84-002 lean), it MUST
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

#### Cluster 5 — Transport coexistence with Connect / Kong (FR-B84-040 → 041)

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
`gateway.yaml` standard MUST NOT, by itself, break these gates; a new
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
