<!-- Audit: B.8.4 (b8-4-envoy-gateway) — verify-then-pin evidence ledger -->
# Verify-then-pin Evidence — b8-4-envoy-gateway

This file records the LIVE-verified pins consumed by `.forge/standards/gateway.yaml`
and the `2.0.0/infra/k8s/envoy-gateway/` template tree. Verified at
`/forge:implement` per ADR-B84-005 (Q-005) and the kong / b8-coroot / b8-signoz
verify-then-pin lesson (pins are resolved live on the registry / CRD bundle,
never fabricated upstream of implement). Verification date: **2026-05-31**.

The four resolutions below close the prior `[NEEDS CLARIFICATION]`
(`BackendTLSPolicy` apiVersion drift) recorded in specify/design.

---

## Pin 1 — Envoy Gateway Helm chart version: `v1.8.0`

- **Value**: `v1.8.0` (latest stable).
- **OCI coordinate**: `oci://docker.io/envoyproxy/gateway-helm` `--version v1.8.0`.
- **Source**: Envoy Gateway GitHub `releases/latest` (resolved 2026-05-13) →
  `v1.8.0` is the current stable tag for the `envoyproxy/gateway` project; the
  Helm chart is published as the OCI artifact `docker.io/envoyproxy/gateway-helm`
  at the matching chart version `v1.8.0`.
- **Consumed by**: `gateway.yaml` `versions.envoy_gateway_chart: "v1.8.0"`;
  `README.md.tmpl` `helm install eg oci://docker.io/envoyproxy/gateway-helm
  --version v1.8.0 -n envoy-gateway-system --create-namespace`.

## Pin 2 — Gateway API CRD bundle version: `v1.5.1`

- **Value**: `v1.5.1`.
- **Source**: Envoy Gateway `v1.8.0` `go.mod` (ref `v1.8.0`) declares
  `sigs.k8s.io/gateway-api v1.5.1` — i.e. the Gateway API CRD bundle that the
  pinned EG `v1.8.0` chart vendors is `v1.5.1`. (Per the specify LOW nit: the
  project release line and the bundle the chart actually vendors are decoupled
  in principle; here they coincide at `v1.5.1`, read from EG's pinned `go.mod`.)
- **Consumed by**: `gateway.yaml` `versions.gateway_api_bundle: "v1.5.1"`.

## Pin 3 — Gateway-API resource apiVersion: `gateway.networking.k8s.io/v1` (incl. BackendTLSPolicy)

- **Value**: `gateway.networking.k8s.io/v1` for ALL four resource kinds shipped
  by this brick — `GatewayClass`, `Gateway`, `HTTPRoute`, **and**
  `BackendTLSPolicy`.
- **Source**: Context7 Gateway API README — `GatewayClass`/`Gateway`/`HTTPRoute`
  are GA at `v1` since Gateway API `v1.0`; **`BackendTLSPolicy` is GA at `v1` as
  of Gateway API `v1.5.1`**. The `v1.5.1` bundle vendored by EG `v1.8.0` ships
  `BackendTLSPolicy` at `v1` in the **Standard** channel — so there is NO
  `v1alpha3`/`v1beta1` form for this brick. This **resolves the prior
  `[NEEDS CLARIFICATION]`** (`BackendTLSPolicy` apiVersion drift, Q-005): the
  shipped bundle GAs it in Standard, so no `[NEEDS CLARIFICATION]` is surfaced.
- **BackendTLSPolicy v1 field shape**: `spec.targetRefs` (plural) +
  `spec.validation.{wellKnownCACertificates, hostname}` (the GA `v1` shape), NOT
  the legacy singular `targetRef` / `tls` shape.
- **Consumed by**: every `.tmpl` apiVersion line in the template tree.

## Pin 4 — GatewayClass controllerName: `gateway.envoyproxy.io/gatewayclass-controller`

- **Value**: `gateway.envoyproxy.io/gatewayclass-controller` (Envoy Gateway
  default controller name).
- **Source**: Context7 Envoy Gateway config-api — the default
  `GatewayClass.spec.controllerName` for the Envoy Gateway controller is
  `gateway.envoyproxy.io/gatewayclass-controller`.
- **Consumed by**: `gatewayclass.yaml.tmpl` `spec.controllerName`.

---

## Auditability note

These four pins are written CONCRETELY into the shipped standard + templates
(no `VERIFY_THEN_PIN` / `<…>` placeholders remain in shipped files), because
they are now LIVE-verified. The b8-4 harness T-009 anti-hallucination guard
asserts that the concrete pins present in the tree are sourced from
`gateway.yaml` (the apiVersion literal `gateway.networking.k8s.io/v1` is the
GA-channel constant, and the chart/bundle semver pins live only in
`gateway.yaml` `versions:`, not hard-coded loose in the manifests).
