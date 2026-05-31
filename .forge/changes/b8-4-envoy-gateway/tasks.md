<!-- Audit: B.8.4 (b8-4-envoy-gateway) -->
# Tasks: b8-4-envoy-gateway

TDD-ordered. Impl-ordering protects the b8-3/b8-3b sibling harnesses: the
`gateway.yaml` standard + its REVIEW/index registration land BEFORE the
`2.0.0.yaml` envoy-component edit (else b8-3 T-011 / b8-3b discovery break).
Concrete versions are **verify-then-pin LIVE** here (b8-coroot lesson).

## Phase 0 — Verify-then-pin (LIVE, before any pin is written)
- [x] **T001** Verify the current Envoy Gateway Helm chart version on the OCI
  registry (`oci://docker.io/envoyproxy/gateway-helm`) — record the concrete
  version + the Gateway API CRD bundle it vendors. [Story: FR-B84-033, NFR-B84-005]
  → `v1.8.0` chart + `v1.5.1` bundle, recorded in `evidence.md` §1/§2.
- [x] **T002** Verify the Gateway API GA version + the `BackendTLSPolicy`
  apiVersion + channel that the pinned bundle actually ships (resolves the
  [NEEDS CLARIFICATION] from specify). Record evidence. [Story: FR-B84-013]
  → `gateway.networking.k8s.io/v1` (BackendTLSPolicy GA v1 Standard channel as of
  GW-API v1.5.1, no v1alpha3/v1beta1), `evidence.md` §3.
- [x] **T003** Verify the `GatewayClass.spec.controllerName` for Envoy Gateway.
  [Story: FR-B84-011] → `gateway.envoyproxy.io/gatewayclass-controller`,
  `evidence.md` §4.

## Phase 1 — Harness RED
- [x] **T004** Author `.forge/scripts/tests/b8-4.test.sh` (12 L1 per design),
  run → RED (tree + standard absent). [Story: FR-B84-040/041]
  → RED confirmed: 8 failed / 4 passed.

## Phase 2 — Standard GREEN (FIRST, protects b8-3/b8-3b)
- [x] **T005** Create `.forge/standards/gateway.yaml` (root; J.7 frontmatter +
  verified `versions:` pins) → REVIEW.md birth ledger row `| gateway.yaml | 1.0.0 |`
  → `index.yml` trigger entry. Validate dir-mode: `validate-standards-yaml.sh
  .forge/standards/` exit 0. [Story: FR-B84-030/031] → exit 0, [STD-PASS] gateway.yaml.

## Phase 3 — Schema edit (AFTER standard exists)
- [x] **T006** Edit `2.0.0.yaml` envoy component: `pin_source: B.8.4` →
  `standard: gateway.yaml`. Re-run b8-3 (17/17) + b8-3b (12/12) — MUST stay GREEN.
  [Story: FR-B84-032] → b8-3 17/17, b8-3b 12/12 GREEN.

## Phase 4 — Template tree GREEN
- [x] **T007** Create `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`:
  `kustomization.yaml.tmpl`, `gatewayclass.yaml.tmpl`, `gateway.yaml.tmpl`,
  `httproute.yaml.tmpl`, `backendtlspolicy.yaml.tmpl`, `README.md.tmpl` (Helm
  install doc). Gateway-API-native, additive (routes to fsm-backend ∥ Kong).
  [Story: FR-B84-010..014, FR-B84-020..022]
- [x] **T008** Run b8-4.test.sh → 12/12 GREEN. [Story: FR-B84-*]

## Phase 5 — Integration
- [x] **T009** Register `b8-4.test.sh` one-line in forge-ci.yml harness loop.
  [Story: FR-B84-040] → registered after b8-3b; forge-ci.yml 277/300.
- [x] **T010** CHANGELOG `[Unreleased]` entry.

## Phase 6 — Verification
- [x] **T011** Full gate sweep: verify.sh PASS, constitution-linter PASS,
  b8-3 17/17, b8-3b 12/12, b8-4 12/12, 1.0.0 Kong tree + schema.yaml byte-untouched.
- [x] **T012** Independent reviewer validates impl before archive. (author does
  NOT self-approve — independent review + maintainer gate-sweep follow)
