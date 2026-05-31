# Proposal: b8-4-envoy-gateway

<!-- Created: 2026-05-31 -->
<!-- Schema: default -->
<!-- Audit: B.8.4 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0 migration, first real 2.0.0 template brick: Envoy Gateway templates) -->

## Problem

B.8 migrates `full-stack-monorepo / 1.0.0` → `2.0.0` (the point of no
return, plan §4) under an **additive-first, breaking-second** strategy
(§4.1): new components are added **in parallel** with the 1.0.0 components,
and the actual `1.0.0 → 2.0.0` bump plus removal of Kong / Temporal /
REST-bridge happens at **B.8.14**, not before.

B.8.3 (`b8-3-schema-candidate`, archived 2026-05-30) declared the 2.0.0
TARGET as a reference-only candidate at
`.forge/schemas/full-stack-monorepo/2.0.0.yaml`. For the gateway it records:

```yaml
- name: envoy-gateway
  role: api-gateway
  replaces: kong          # 1.0.0 baseline: kong:3.6 (docs/B8-BASELINE.md §1)
  delivered_by: B.8.4
  pin_source: B.8.4       # no *.yaml standard pins a gateway today (ADR-B8-3-002)
```

and a migration delta:

```yaml
- from: kong-gateway
  to: envoy-gateway
  brick: B.8.4
  strategy: additive-first  # Envoy added in parallel, Kong removed at B.8.14
```

**B.8.4 is the first real template brick of the 2.0.0 migration and the
first consumer of the B.8.3 candidate schema.** It is where the Envoy
Gateway version pin and its standard source are *created* (`pin_source:
B.8.4`). Today there is **no** Envoy Gateway template tree, and **no
`*.yaml` standard pins a gateway** — the only gateway standard is the
markdown `.forge/standards/infra/kong.md` (confirming `pin_source: B.8.4`:
the pin does not exist yet and is born here).

**Ground truth (re-read 2026-05-31, Article III.4):**

- **1.0.0 gateway today is Kong, expressed two ways.** (1) A declarative
  example template `.forge/templates/archetypes/full-stack-monorepo/infra/
  kong/kong.yml.example.tmpl` (DB-less mode, `services` → `fsm-backend`,
  citing "Article VIII.1 (API gateway via Kong, declarative only)").
  (2) A markdown standard `.forge/standards/infra/kong.md` (Kong plugins,
  decK, gRPC transcoding) — **NOT** a `*.yaml` version-pin standard. There
  is no `gateway.yaml` or equivalent. This confirms B.8.3
  ADR-B8-3-002 and the `pin_source: B.8.4` marker.
- **The 1.0.0 templates live FLAT** under
  `.forge/templates/archetypes/full-stack-monorepo/` with **no version
  subdir**: `infra/k8s/base/{deployment,service,serviceaccount,ingress,
  kustomization}.yaml.tmpl` + `obi-daemonset` + `coroot-deployment` +
  `overlays/{dev,staging,prod}/`, and `infra/kong/`. The plan §4.2 B.8.4
  text names the path `templates/full-stack-monorepo/2.0.0/infra/k8s/
  envoy-gateway/` — a **versioned** subdir that does not exist on disk
  today. This contradiction (plan's versioned 2.0.0 tree vs the live flat
  1.0.0 tree) directly parallels the B.8.3 versioned-schema coexistence
  decision (`2.0.0.yaml` sibling next to flat `schema.yaml`). **Recorded,
  not normalized** (→ Q-001 / ADR-B84-001).
- **The 1.0.0 K8s base is kustomize-based**, controller-agnostic: a
  `kustomization.yaml.tmpl` lists `deployment/service/serviceaccount/
  ingress`, with `commonLabels` and per-environment overlays patching
  namespace/image/replicas/resources (standard
  `.forge/standards/infra/k8s-overlays.md`). The plan §4.2 B.8.4 says
  "Helm chart Atlas-fourni" AND "Gateway API natifs". Whether B.8.4 ships
  a **Helm chart** (departing from the kustomize convention) or **raw
  kustomize manifests** consistent with the existing 1.0.0 `k8s/base/` is a
  genuine decision (→ Q-003 / ADR-B84-003).
- **The 2.0.0 candidate is `scaffoldable: false`** (ADR-B8-3-003/005). Its
  template tree is therefore **not scaffolded by default** by `forge init`;
  these Envoy templates are additive on-disk assets gating B.8.12 /
  B.8.14, invisible to default scaffolding until B.8.14 promotes 2.0.0 to
  `stable`.
- **Standard frontmatter contract (observed, J.7-enforced).** Every
  `.forge/standards/*.yaml` carries `version` / `last_reviewed` /
  `expires_at` / `exception_constitutional` / `linter_rule` /
  `enforcement{ci_blocking,pre_commit_hook}` / `forbidden` / `rationale`,
  optionally a `versions:` pin map and `pin_review_cadence:` (ISO 8601),
  validated by `bin/validate-standards-yaml.sh` (J.7). A NEW gateway
  standard, if B.8.4 creates one, MUST satisfy that contract and register
  in `.forge/standards/index.yml` + `.forge/standards/REVIEW.md`. The pin
  itself is **verify-then-pin** (see below).

**External research (Context7, 2026-05-31 — Article III.4; evidence in
`specs.md` § "Anti-Hallucination Pass / Context7 evidence"):**

- **Envoy Gateway** (`/envoyproxy/gateway`) ships a Helm chart distributed
  as an **OCI artifact** at `oci://docker.io/envoyproxy/gateway-helm`,
  installed via `helm install eg oci://docker.io/envoyproxy/gateway-helm
  --version <ver> -n envoy-gateway-system --create-namespace`. The chart
  installs Envoy Gateway **and its required Gateway API CRDs**. The current
  docs tree is the **v1.8 release line** (doc source URLs
  `.../en/v1.8/install/install-helm.md`); doc snippets render the chart
  version as a `{{< helm-version >}}` placeholder, so the **concrete
  registry-verified version is NOT pinned here** — deferred to
  verify-then-pin at `/forge:implement` (kong/b8-coroot lesson).
- **Gateway API** (`/kubernetes-sigs/gateway-api`): the latest supported
  API version is **`v1`**, released by **v1.5.1** of the project, with GA
  support for `v1.GatewayClass`, `v1.Gateway`, `v1.HTTPRoute`,
  `v1.GRPCRoute`, `v1.TLSRoute`, **`v1.BackendTLSPolicy`**, and
  `v1.ReferenceGrant`. `Gateway`/`GatewayClass`/`HTTPRoute` graduated to
  `gateway.networking.k8s.io/v1` in the v1.0 release. **`BackendTLSPolicy`
  has historically moved across API versions** (`v1beta1` and `v1alpha3` in
  earlier docs, **`v1` GA as of v1.5.1**) — so its exact `apiVersion` is
  pinned to the concrete Gateway API CRD bundle that ships, and is flagged
  `[NEEDS CLARIFICATION]` / verify-then-pin (see Q-005).

## Solution

Author the **specification for** the Envoy Gateway template brick (B.8.4):
the required template files, the Gateway-API resource shapes
(`Gateway` / `HTTPRoute` / `BackendTLSPolicy` + the `GatewayClass` they
bind to), the Helm-vs-kustomize delivery model, the additive-first
coexistence with Kong, and the gateway version-pin source. **B.8.4 (this
change) ships NO templates and NO concrete version pins as code** — this is
propose + specify only. The template tree, the Envoy Gateway Helm/CRD pin,
and the gateway standard (if any) are built in the implementation phase,
where the pin is **verified live on the registry then pinned**.

When built, the Envoy Gateway brick MUST:

1. **Live in a NEW, versioned, additive 2.0.0 template tree** rooted at
   `.forge/templates/archetypes/full-stack-monorepo/2.0.0/...` (mirroring
   how `2.0.0.yaml` sits beside the flat `schema.yaml`), with the Envoy
   resources under `.../2.0.0/infra/k8s/envoy-gateway/` per plan §4.2 B.8.4
   — **coexisting** with, and **byte-untouching**, the flat 1.0.0 tree and
   `infra/kong/` (→ ADR-B84-001).
2. Provide **Gateway API native** resources: a `GatewayClass` bound to the
   Envoy Gateway controller, a `Gateway` with listener(s), one or more
   `HTTPRoute`s routing to the backend Service, and a `BackendTLSPolicy`
   for upstream TLS validation — each at the **API version of the concrete
   Gateway API CRD bundle shipped** (not invented; → Q-005).
3. Express the **Envoy Gateway installation** consistent with the chosen
   delivery model (Helm chart `oci://docker.io/envoyproxy/gateway-helm` per
   plan "Helm chart Atlas-fourni", vs raw kustomize manifests matching the
   1.0.0 `k8s/base/` convention — → ADR-B84-003), with the chart/CRD
   version sourced from the gateway pin created by this brick.
4. Be **additive-first**: Envoy is added **in parallel** with Kong (canary
   by route per §4.1). B.8.4 MUST NOT remove `infra/kong/`, MUST NOT touch
   the frozen 1.0.0 tree, and MUST NOT amend Constitution Article VIII.1
   (Kong SHALL) — that amendment, if any, belongs to B.8.14 (→ ADR-B84-004,
   "Constitution Compliance" below).
5. **Create the gateway version pin + its standard source** (this is the
   `pin_source: B.8.4` contract). Either a NEW gateway standard
   (e.g. `.forge/standards/gateway.yaml`) holding the Envoy Gateway
   Helm chart + Gateway API CRD bundle pins under the J.7 frontmatter
   contract, or an extension of an existing standard — decided by
   ADR-B84-002. The concrete versions are **verify-then-pin at implement**,
   never fabricated here.

Decisions reserved for `/forge:design` (ADRs), leanings stated, open where
genuinely undecided (see `open-questions.md`):

- **ADR-B84-001 — versioned 2.0.0 template tree (path reconciliation).**
  Plan §4.2 B.8.4 names `templates/full-stack-monorepo/2.0.0/infra/k8s/
  envoy-gateway/`; the live 1.0.0 templates are FLAT under
  `full-stack-monorepo/` with no version subdir. **Lean:** create the new
  `.../full-stack-monorepo/2.0.0/` subtree (mirroring the `2.0.0.yaml`
  schema sibling), coexisting with the flat 1.0.0 tree, Envoy under
  `2.0.0/infra/k8s/envoy-gateway/`. Whether scaffolder/snapshot tooling
  must learn the versioned template root (paralleling the B.8.3.b validator
  rewiring) is flagged as possibly a separate concern. Resolved at design
  by an independent reviewer + maintainer.
- **ADR-B84-002 — gateway pin source (`pin_source: B.8.4`).** The 2.0.0.yaml
  envoy component has `pin_source: B.8.4` and **no `standard:` ref**.
  **Lean:** create a NEW `.forge/standards/gateway.yaml` (J.7
  frontmatter-compliant) holding the Envoy Gateway Helm chart pin + the
  Gateway API CRD bundle pin, register it in `index.yml` + `REVIEW.md`, and
  add a `standard: gateway.yaml` ref to the 2.0.0.yaml envoy component.
  **NOTE:** editing `2.0.0.yaml` is permitted for B.8.4 because it is the
  *candidate* (not the frozen 1.0.0 `schema.yaml`); this must be explicitly
  confirmed + ADR'd. Alternative (b): keep `pin_source` as-is and pin the
  versions inside the template/chart values only. Resolved at design.
- **ADR-B84-003 — Helm chart vs raw kustomize manifests.** Plan says "Helm
  chart Atlas-fourni" + "Gateway API natifs"; the 1.0.0 infra is
  kustomize-based and controller-agnostic. **Lean:** the *control-plane
  install* (Envoy Gateway controller + CRDs) is the **Helm chart**
  (`oci://docker.io/envoyproxy/gateway-helm`, Atlas-provided), while the
  *data-plane intent* (`GatewayClass`/`Gateway`/`HTTPRoute`/
  `BackendTLSPolicy`) ships as **Gateway-API-native manifests under
  kustomize**, consistent with the 1.0.0 `k8s/base/` + overlays pattern.
  Exact split (single Helm chart that templates everything vs Helm-for-
  controller + kustomize-for-resources) decided at design.
- **ADR-B84-004 — additive-first wiring (Envoy ∥ Kong).** **Lean:** ship
  Envoy resources alongside the existing Kong example, both targeting the
  same `fsm-backend` upstream, enabling canary-by-route per §4.1. B.8.4
  removes nothing; the route-cutover/canary mechanism and Kong removal are
  B.8.10 (migration script) / B.8.14 (bump + removal). Documented so
  B.8.12's zero-regression gate has a clear coexistence contract.
- **ADR-B84-005 — REST↔gRPC transcoding parity (open).** Kong (VIII.1)
  carries REST↔gRPC transcoding via the `grpc-gateway` plugin. Under 2.0.0
  the transport target is **Connect-RPC** (`transport.yaml` v1.2.0,
  delivered by B.8.6), and the §4.2 caveats note "garder gRPC-Web standard
  via Envoy Gateway" as a fallback. Whether B.8.4's `HTTPRoute`s assume
  Connect/gRPC-Web pass-through (no gateway-side transcoding) or must
  replicate Kong's transcoding is **genuinely undecided** and couples to
  B.8.6 — flagged (→ Q-004), resolved at design, not guessed.

Release vehicle: maintainer-set (additive template + standard brick on the
2.0.0 candidate; no change to default 1.0.0 scaffolding behavior).

## Scope In

- `proposal.md`, `specs.md`, `.forge.yaml`, `open-questions.md` for
  `b8-4-envoy-gateway` (this change): authoring requirements + ADRs +
  open questions for the Envoy Gateway template brick.
- Requirement set (`FR-B84-*` / `NFR-B84-*`) defining WHAT the Envoy
  Gateway templates, the Gateway-API resource shapes, the delivery model,
  the gateway pin source, and the additive-first coexistence with Kong must
  contain.
- ADRs `ADR-B84-001..005` capturing the versioned-tree path, the gateway
  pin source, the Helm-vs-kustomize model, the additive-first wiring, and
  the transcoding-parity decision.
- Identification (via Context7) of the Envoy Gateway Helm chart coordinates
  + the Gateway API resource API shapes, with the concrete version pins
  **deferred to verify-then-pin at `/forge:implement`**.

## Scope Out (Explicit Exclusions)

- **Building the Envoy Gateway template tree itself**
  (`.../full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/**`) — that is the
  implementation phase of B.8.4, authored AFTER design from these specs.
  NOT created now.
- **Concrete Envoy Gateway / Gateway API version pins** — the chart version
  and the CRD-bundle API versions are **verify-then-pin at implement**
  (live `helm`/registry + `kubectl`/CRD check), never fabricated in
  propose/specify. This change identifies the components + API shapes only.
- **The gateway standard file itself** (`gateway.yaml` or equivalent)
  — authored in the impl phase under ADR-B84-002 with the verified pin.
- **Editing the frozen 1.0.0 template tree** or `infra/kong/` — additive
  only; Kong stays in parallel (additive-first §4.1). Removal is B.8.14.
- **Removing Kong / amending Constitution Article VIII.1** — B.8.14
  territory (GOVERNANCE.md amendment process). B.8.4 ships Envoy additively
  and the candidate's non-scaffoldable 2.0.0 tree, so no amendment is
  needed yet (see "Constitution Compliance").
- **Connect-RPC handlers / transport codegen** (B.8.6), **DBOS** (B.8.5),
  **Zitadel** (B.8.7), **Qwik web-public** (B.8.9), **migration script**
  (B.8.10), **zero-regression E2E** (B.8.12), **schema bump** (B.8.14).
- **Validator / scaffolder rewiring** to discover the versioned 2.0.0
  template root — flagged in ADR-B84-001 as a possible separate concern,
  NOT done here (mirrors the B.8.3 → B.8.3.b separation).
- **`mobile-pwa-first` / other archetypes** — B.9+ territory.

## Impact

- **Users affected**: B.8 migration architects (Envoy templates are the
  first concrete realization of the 2.0.0 candidate's gateway component) and
  B.8.10 / B.8.12 / B.8.14 (which consume the Envoy tree). **No effect on
  current 1.0.0 adopters** — the flat 1.0.0 tree + `infra/kong/` are
  untouched and the 2.0.0 candidate is `scaffoldable: false` (not scaffolded
  by default).
- **Technical impact**: spec artifacts only in this change. Downstream, a
  new additive `2.0.0/` template subtree appears alongside the flat 1.0.0
  tree; a gateway pin + standard source are created (`pin_source: B.8.4`);
  the 2.0.0.yaml envoy component may gain a `standard:` ref (candidate edit,
  ADR-B84-002).
- **Dependencies**: depends on B.8.3 (the candidate schema declares the
  envoy-gateway component + the kong→envoy migration delta this brick
  realizes). Gates / feeds B.8.10 (migration orchestration), B.8.12
  (zero-regression gate asserts convergence to the 2.0.0 gateway target),
  B.8.14 (Kong removal + bump). Coexists with B.8.6 (Connect transport) —
  see Q-004.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: this is the propose+specify
  gate; no implementation precedes it. The Envoy templates + gateway pin are
  built only after design from these specs.
- **Article III.4 (Anti-Hallucination)**: the gateway-today reality (Kong
  example + markdown `kong.md`, no `*.yaml` gateway pin), the flat-1.0.0
  template layout, and the standard frontmatter contract are re-read from
  live files. The Envoy Gateway Helm coordinates + Gateway API resource
  shapes are sourced from **Context7** (evidence recorded in `specs.md`),
  and the **concrete version pins are explicitly deferred to verify-then-pin
  at implement** — the `BackendTLSPolicy` API-version drift (v1beta1 /
  v1alpha3 / v1-GA) is flagged `[NEEDS CLARIFICATION]` (Q-005), not guessed.
  The plan-vs-live path contradiction (versioned 2.0.0 tree vs flat 1.0.0)
  is recorded, not normalized (Q-001).
- **Article IV (Delta-based)**: the 2.0.0 tree is a NEW additive sibling;
  it does not rewrite or delete the flat 1.0.0 tree or `infra/kong/`. If the
  2.0.0.yaml envoy component gains a `standard:` ref, that is an additive
  edit to the *candidate* (permitted), not the frozen 1.0.0 surface.
- **Article V (Compliance gate)**: ADRs map each open question to a design-
  phase resolution; no work proceeds around the unresolved path / pin-source
  / delivery-model / transcoding questions.
- **Article VIII.1 (Kong SHALL — IN FORCE)**: Constitution v1.1.0 §VIII.1
  mandates Kong as the API gateway, and the 2.0.0 candidate header records
  that this prohibition **remains binding until B.8.14** completes the
  GOVERNANCE.md amendment process. **B.8.4 does NOT violate VIII.1 and does
  NOT need the amendment yet**, because: (1) it ships Envoy Gateway templates
  **additively, in parallel** with Kong (§4.1 additive-first) — Kong is not
  removed and the 1.0.0 gateway stays Kong; (2) the Envoy templates live in
  the 2.0.0 **candidate** tree, which is `scaffoldable: false` and therefore
  **not deployed by any default scaffold**. Authoring/standing-up
  non-scaffoldable additive templates that describe the future target is not
  "using a non-Kong gateway" in any live stack. The amendment to VIII.1, if
  any, lands with the actual Kong removal + bump at **B.8.14**. This
  compliance position is stated explicitly so the gate is unambiguous.
- **Article VIII.5 (IaC) / X (quality)**: the Envoy templates are
  version-controlled IaC; the gateway pin lands under the J.7-validated
  standard contract with a `pin_review_cadence` (when the standard is
  created). No relaxation of TDD/BDD/coverage.
- **Article XII (Governance)**: no Constitution amendment here. The VIII.1
  amendment, if any, lands with the actual bump + Kong removal at B.8.14.

## Open Questions (seed)

- **Q-001** — versioned 2.0.0 template tree path (`.../2.0.0/infra/k8s/
  envoy-gateway/`) vs the flat live 1.0.0 convention; possible
  scaffolder/snapshot rewiring (→ ADR-B84-001; open, resolved at
  `/forge:design`).
- **Q-002** — gateway pin source: NEW `gateway.yaml` standard +
  `standard:` ref added to the 2.0.0.yaml envoy component, vs pin-in-
  template-only (→ ADR-B84-002; open).
- **Q-003** — Helm chart vs raw kustomize manifests for the Envoy
  control-plane + data-plane resources (→ ADR-B84-003; open).
- **Q-004** — REST↔gRPC transcoding parity vs Connect/gRPC-Web pass-through
  (couples to B.8.6 transport) (→ ADR-B84-005; open).
- **Q-005** — concrete Envoy Gateway Helm chart version + the `Gateway` /
  `HTTPRoute` / `BackendTLSPolicy` API versions of the shipped CRD bundle
  (esp. `BackendTLSPolicy` v1beta1/v1alpha3/v1-GA drift) — **verify-then-pin
  at `/forge:implement`**, flagged `[NEEDS CLARIFICATION]` here, not guessed
  (→ design + impl).
