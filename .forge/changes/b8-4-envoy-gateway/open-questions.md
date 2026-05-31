# Open Questions — b8-4-envoy-gateway

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN sequential, never reused.
Author phase: leanings recorded; resolutions are made at /forge:design by an
INDEPENDENT reviewer + the maintainer, NOT self-approved here.

## Resolution log

- (none yet — author phase. Independent review + maintainer resolutions land
  here at /forge:design. Q-005 (concrete pins / API versions) additionally
  carries a verify-then-pin step at /forge:implement.)
-->

## Q-001: Versioned 2.0.0 template tree vs the flat 1.0.0 convention

- **Status**: open
- **Raised in**: `proposal.md` (ADR-B84-001 seed), `specs.md` FR-B84-001/002/004
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-4 specify pass)

### Question

Plan §4.2 B.8.4 names the artifact path
`templates/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/` — a **versioned**
subdir. But the live 1.0.0 templates are **FLAT** under
`.forge/templates/archetypes/full-stack-monorepo/` with **no version subdir**
(`infra/k8s/base/`, `infra/kong/`, overlays, `Taskfile.yml.tmpl`, etc.). There
is no `2.0.0/` template root today. This is the template-tree analogue of the
B.8.3 schema decision (`2.0.0.yaml` versioned sibling beside flat `schema.yaml`).

`[NEEDS CLARIFICATION: Should the 2.0.0 Envoy templates be authored under a NEW
versioned subtree `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...`
(Envoy at `2.0.0/infra/k8s/envoy-gateway/`) coexisting with the byte-untouched
flat 1.0.0 tree — and is teaching the scaffolder/snapshot tooling to discover a
versioned template root a SEPARATE downstream concern (paralleling the B.8.3.b
validator rewiring), out of B.8.4 scope?]`

- (a) **Versioned sibling subtree `.../2.0.0/...`, scaffolder awareness
  deferred** — flat 1.0.0 tree stays byte-stable (honors B.8.2 freeze + the
  candidate `scaffoldable: false`). Envoy tree exists on disk as an additive
  asset gating B.8.10/B.8.12/B.8.14. Scaffolder/snapshot rewiring to discover
  the versioned template root = separate concern (like B.8.3.b). **Lean here**
  — mirrors the ratified B.8.3 versioned-sibling precedent; freeze-safe.
- (b) **Restructure into `1.0.0/` + `2.0.0/` versioned roots, retire the flat
  tree** — cleanest long-term but **edits/moves the frozen 1.0.0 surface** →
  violates B.8.2 freeze + likely breaks scaffolder paths today. Rejected for
  B.8.4 scope.
- (c) **Place Envoy templates inside the flat tree (no `2.0.0/` subdir)** —
  contradicts plan §4.2's explicit `2.0.0/` path and risks the 2.0.0 candidate
  bleeding into default 1.0.0 scaffolding. Disfavored.

### Resolution

- **Resolved on**: _pending (/forge:design, independent reviewer + maintainer)_
- **Decision**: _pending_
- **Rationale**: _pending_

---

## Q-002: Gateway pin source — new `infra/gateway.yaml` standard + candidate `standard:` ref

- **Status**: open
- **Raised in**: `proposal.md` (ADR-B84-002 seed), `specs.md` FR-B84-030/031/032
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-4 specify pass)

### Question

The 2.0.0.yaml `envoy-gateway` component carries `pin_source: B.8.4` and **no
`standard:` ref** (B.8.3 ADR-B8-3-002 — the Envoy pin had no standard source and
was deferred to B.8.4). No `*.yaml` standard pins a gateway today (only markdown
`infra/kong.md`). Where does the Envoy Gateway version pin live?

`[NEEDS CLARIFICATION: Should B.8.4 create a NEW J.7-compliant standard
`.forge/standards/infra/gateway.yaml` (Envoy Gateway Helm chart + Gateway API
CRD bundle pins, frontmatter contract, index.yml + REVIEW.md registration) and
add a `standard: gateway.yaml` ref to the 2.0.0.yaml envoy component (a
permitted *candidate* edit) — or keep `pin_source: B.8.4` and pin only inside
the Helm chart values / template literals?]`

- (a) **New `infra/gateway.yaml` standard + add `standard:` ref to the candidate
  envoy component** — single source of truth, J.7-validated, `pin_review_cadence`
  for verify-then-pin freshness; resolves the 2.0.0.yaml gap. Editing
  `2.0.0.yaml` is allowed because it is the **candidate** (not the frozen 1.0.0
  `schema.yaml`) — **must be explicitly confirmed**. **Lean here.**
- (b) **Keep `pin_source: B.8.4`, pin in chart values only** — no new standard,
  no candidate edit; but the pin is not J.7-governed and drifts without a review
  cadence. Disfavored (loses the standards-lifecycle guardrail).

### Resolution

- **Resolved on**: _pending (/forge:design)_
- **Decision**: _pending_
- **Rationale**: _pending_

---

## Q-003: Helm chart vs raw kustomize manifests for the Envoy resources

- **Status**: open
- **Raised in**: `proposal.md` (ADR-B84-003 seed), `specs.md` FR-B84-020/021
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-4 specify pass)

### Question

Plan §4.2 B.8.4 says "Templates **Helm** Envoy Gateway" + "Helm chart
Atlas-fourni" AND "`Gateway`, `HTTPRoute`, `BackendTLSPolicy` Gateway API
natifs". The live 1.0.0 infra is **kustomize-based** and controller-agnostic
(`infra/k8s/base/kustomization.yaml.tmpl` lists deployment/service/
serviceaccount/ingress; overlays patch namespace/image/replicas; standard
`infra/k8s-overlays.md`). Context7 confirms the Envoy Gateway control plane
installs via the Helm chart `oci://docker.io/envoyproxy/gateway-helm`.

`[NEEDS CLARIFICATION: What is the delivery model — (a) Helm chart for the Envoy
Gateway control-plane install + Gateway-API-native manifests under kustomize for
the data-plane resources (consistent with the 1.0.0 k8s/base + overlays
convention); (b) a single Helm chart that also templates the Gateway/HTTPRoute/
BackendTLSPolicy; or (c) raw kustomize manifests for everything (controller
install expressed as manifests, no Helm)?]`

- (a) **Helm for control-plane install, kustomize for data-plane resources** —
  honors "Helm chart Atlas-fourni" for the controller+CRDs while keeping the
  `GatewayClass`/`Gateway`/`HTTPRoute`/`BackendTLSPolicy` as Gateway-API-native
  kustomize manifests like the 1.0.0 `k8s/base/`. **Lean here** (best fit with
  the existing overlay convention).
- (b) **Single Helm chart templates everything** — most "Helm-native" but
  departs furthest from the kustomize 1.0.0 convention; couples data-plane intent
  to chart values.
- (c) **Raw kustomize for everything (no Helm)** — maximal convention
  consistency but contradicts the plan's explicit "Helm chart Atlas-fourni" for
  the install. Disfavored.

### Resolution

- **Resolved on**: _pending (/forge:design)_
- **Decision**: _pending_
- **Rationale**: _pending_

---

## Q-004: REST↔gRPC transcoding parity vs Connect / gRPC-Web pass-through

- **Status**: open
- **Raised in**: `proposal.md` (ADR-B84-005 seed), `specs.md` FR-B84-041
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-4 specify pass)

### Question

Kong (Article VIII.1) carries REST↔gRPC transcoding via the `grpc-gateway`
plugin (`infra/kong.md`). Under 2.0.0 the transport target is **Connect-RPC**
(`transport.yaml` v1.2.0, delivered by B.8.6), and plan §13 caveat 2 names
"gRPC-Web standard via Envoy Gateway" as a fallback. What do B.8.4's `HTTPRoute`s
assume on the gateway side?

`[NEEDS CLARIFICATION: Should the Envoy HTTPRoutes assume Connect/gRPC-Web
pass-through (the backend speaks Connect natively, no gateway-side transcoding —
Kong's grpc-gateway plugin has no Envoy equivalent in scope), or must B.8.4
replicate REST↔gRPC transcoding at the Envoy layer to preserve byte-for-byte
route parity with Kong during the additive-first window? This couples to B.8.6
(Connect transport delivery).]`

- (a) **Connect/gRPC-Web pass-through, no gateway-side transcoding** — aligns
  with the 2.0.0 Connect-RPC transport target (B.8.6) and §13 caveat 2 gRPC-Web
  fallback; the gateway routes, the backend speaks Connect. **Lean here**, but
  explicitly coupled to B.8.6 — confirm the transport story before finalizing.
- (b) **Replicate REST↔gRPC transcoding at Envoy** — preserves exact Kong route
  parity during canary, but adds Envoy transcoding complexity that may be moot
  once Connect-RPC lands (B.8.6). Genuinely undecided.

### Resolution

- **Resolved on**: _pending (/forge:design, with the B.8.6 transport decision)_
- **Decision**: _pending_
- **Rationale**: _pending_

---

## Q-005: Concrete Envoy Gateway chart version + Gateway API resource API versions (verify-then-pin)

- **Status**: open
- **Raised in**: `proposal.md` ("External research" + ADR-B84-005 neighborhood),
  `specs.md` FR-B84-013/033, NFR-B84-005, Context7 Evidence
- **Raised on**: 2026-05-31
- **Raised by**: author (b8-4 specify pass)

### Question

Context7 identifies the Envoy Gateway Helm chart (`oci://docker.io/envoyproxy/
gateway-helm`, v1.8 docs line, version rendered as a `{{< helm-version >}}`
placeholder) and the Gateway API resources (`Gateway`/`GatewayClass`/`HTTPRoute`
GA at `…/v1` since Gateway API v1.0; `BackendTLSPolicy` GA at `…/v1` as of
v1.5.1, but historically at `v1beta1` and `v1alpha3`). The **concrete** chart
version and the **exact** `apiVersion` each resource ships at depend on the
specific CRD bundle the pinned Envoy Gateway release vendors.

`[NEEDS CLARIFICATION: The concrete Envoy Gateway Helm chart version, the
Gateway API CRD bundle version it vendors, and the exact apiVersion of
BackendTLSPolicy (v1beta1 / v1alpha3 / v1) + its release channel (Standard vs
Experimental) MUST be VERIFIED LIVE at /forge:implement (helm show chart / OCI
registry inspect + kubectl explain / CRD bundle-version annotation) before being
written. They MUST NOT be fabricated in propose/specify/design (Article III.4 +
kong/b8-coroot verify-then-pin lesson). If the shipped bundle does not GA
BackendTLSPolicy, the impl MUST surface this rather than guess.]`

- This is a **verify-then-pin** item, not a multiple-choice design decision: the
  value is determined by live registry/CRD inspection at `/forge:implement`. The
  design phase records the verification procedure + acceptance (which channel,
  which apiVersions); the implementation phase performs the live check and pins.

### Resolution

- **Resolved on**: _pending — design records the verify procedure;
  `/forge:implement` performs the LIVE pin_
- **Decision**: _pending_
- **Rationale**: _pending_
