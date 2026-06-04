<!-- Audit: B.8.14 (b8-14-promotion-prep) -->

# Proposed Constitution Amendment — §VIII.1 (API Gateway): Kong → Envoy

**Status**: DRAFT — STAGED, NOT APPLIED. This document is **step 1** of the
`GOVERNANCE.md §"Amendment Process"` (a Forge change targeting
`.forge/constitution.md`). It opens the mandatory **≥ 7-day public discussion
window** (step 2). Ratification (step 3) and application (step 4) are performed
by the follow-up brick `b8-14-promotion-flip` **after** the window closes — see
`flip-runbook.md`. Nothing in this brick edits `.forge/constitution.md`.

## Scope

- **Amends §VIII.1 only.** §VIII.2 (Temporal — Workflow Orchestration) is **NOT**
  amended: B8O (`b8-orchestration-temporal-realign`) retained Temporal as the
  Rust orchestration default (`orchestration.yaml` v1.2.0). The B.8 migration
  removes **Kong + the gateway REST↔gRPC bridge**, not Temporal.

## Current text (in force, Constitution v1.1.0 §VIII.1)

> Kong SHALL be used as the API gateway for routing REST requests to gRPC
> backends. REST↔gRPC transcoding is handled at the gateway layer, not in
> application code. Application services speak gRPC natively.

## Proposed text (Constitution v2.0.0 §VIII.1)

> **Envoy Gateway SHALL** be used as the API gateway, configured via the
> Kubernetes Gateway API (`GatewayClass`/`Gateway`/`HTTPRoute`). Service-to-service
> and client traffic use **Connect-RPC** (Connect/gRPC/gRPC-Web) end-to-end;
> there is no gateway-layer REST↔gRPC transcoding. Application services speak
> gRPC/Connect natively. (The owning standard is `.forge/standards/gateway.yaml`,
> introduced in B.8.4; `.forge/standards/transport.yaml` governs Connect-RPC.)

## Motivation

The 2.0.0 flagship target (plan §4, `2.0.0.yaml`) replaces Kong with Envoy
Gateway (Gateway API native, B.8.4) and the REST-bridge with Connect-RPC (B.8.6),
adopted **additively** in B.8.4–B.8.12 (Envoy ∥ Kong, Connect ∥ REST) and proven
zero-regression by B.8.12. §VIII.1 must change for the 2.0.0 architecture to be
constitutional. Temporal (§VIII.2) stays.

## Impact on existing projects

This is a **breaking** modification of an existing normative requirement:
existing 1.0.0 projects deploy Kong and would **fail** a new Envoy-SHALL §VIII.1.
Per the real `VERSIONING.md:15-17` MAJOR criterion ("the Constitution is amended
in a way that breaks compatibility … its normative requirements are tightened in
a way that existing projects would fail to satisfy"), this is a Constitution
**MAJOR** bump → **v1.1.0 → v2.0.0**. (The matching step-4 semver guidance is
`GOVERNANCE.md:124-125`: "major for removal or breaking modification of an existing
article".) Pre-GA, the framework version stays on the `0.4.0` MINOR line with a
`### BREAKING` CHANGELOG note (pre-1.0 carve-out `VERSIONING.md:70-73`); the
framework MAJOR follows at GA. Migration path: `docs/MIGRATIONS.md` (additive
overlay) + `docs/ROLLBACK.md` (B.8.13) + the 1.0.0 deprecation window (T+6 months).

## Process (GOVERNANCE.md §"Amendment Process", steps 1–4)

1. **Open a Forge change** targeting `.forge/constitution.md` — **this change**
   (`b8-14-promotion-prep`).
2. **Public discussion ≥ 7 days** (7 jours) — opened by this document; publicly
   visible (PR/Discussion thread). Closed-door amendments are not allowed.
3. **Ratification** by the BDFL (Phase actuelle).
4. **Apply** (follow-up `b8-14-promotion-flip`): add the Amendments row below to
   `.forge/constitution.md`, bump the `**Version**` line to `v2.0.0`, and update
   `.forge/templates/change.yaml` + archetype `.forge.yaml.tmpl` constitution
   version. Precedent: `d5-governance` (the canonical first instance, → v1.1.0).

## Proposed `## Amendments` table row (to add at application, step 4)

| Amendment | Date | Description | Ratified By |
|-----------|------|-------------|-------------|
| 2 | <ratification-date> | Amend §VIII.1 — replace Kong with Envoy Gateway (Gateway API) as the mandated API gateway; replace gateway-layer REST↔gRPC transcoding with end-to-end Connect-RPC. Constitution v1.1.0 → v2.0.0 (breaking). §VIII.2 (Temporal) unchanged. | Benoit Fontaine (BDFL) |
