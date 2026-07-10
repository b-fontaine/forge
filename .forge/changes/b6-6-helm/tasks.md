# Tasks: b6-6-helm

<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: B.6.6 (b6-6-helm) — production Helm Temporal cluster + NATS JetStream + T2/T3 docs -->

Each task cites its Story (FR/NFR) per the tasks.md linter contract.

## RED — TDD gate first

- [x] **T1** [Story: FR-B6-HELM-001, NFR-B6-HELM-004] Author
  `.forge/scripts/tests/b6-6.test.sh` (13 L1 + 1 L2 skip-pass) mirroring
  `b8-4.test.sh` / `b6-2.test.sh`. Commit + run → RED (no templates yet).

## GREEN — Temporal cluster chart

- [x] **T2** [Story: FR-B6-HELM-001] Create
  `infra/k8s/temporal-cluster/values-forge.yaml.tmpl` — verify-then-pin against
  `temporal/temporal 1.5.0` LIVE.
- [x] **T3** [Story: FR-B6-HELM-002] Enable + size the four roles
  (frontend/history/matching/worker).
- [x] **T4** [Story: FR-B6-HELM-003, ADR-B6-HELM-002] Postgres datastores
  (`persistence.datastores.{default,visibility}.sql`, `pluginName: postgres12`,
  `existingSecret`); NO cassandra / NO `persistence.default`.
- [x] **T5** [Story: FR-B6-HELM-004, FR-B6-HELM-005] `numHistoryShards` +
  schema-setup Job / admintools wiring.
- [x] **T6** [Story: FR-B6-HELM-001, FR-B6-HELM-040] `temporal-cluster/README.md.tmpl`
  — Atlas-provided `helm install`, ops, T1/T2/T3 posture citing
  `compliance-tiers.md`, client-SDK ⟂ server-pin note (no re-pin).

## GREEN — NATS JetStream chart

- [x] **T7** [Story: FR-B6-HELM-020] Create
  `infra/k8s/nats-jetstream/values-forge.yaml.tmpl` — verify-then-pin against
  `nats/nats 2.14.2` LIVE.
- [x] **T8** [Story: FR-B6-HELM-021, FR-B6-HELM-022, FR-B6-HELM-023] 3-node RAFT
  cluster + JetStream file-store PVC + monitor endpoint.
- [x] **T9** [Story: FR-B6-HELM-020, FR-B6-HELM-024, FR-B6-HELM-040]
  `nats-jetstream/README.md.tmpl` — `helm install`, durable-consumer/queue-group
  provisioning, T1/T2/T3 posture.

## GREEN — Docs + registration

- [x] **T10** [Story: FR-B6-HELM-041] `infra/k8s/README.md.tmpl` index (prod
  charts vs dev backbone; links to `docs/COMPLIANCE.md`).
- [x] **T11** [Story: FR-B6-HELM-050] Register all 5 new `.tmpl` in
  `event-driven-eu/scaffold-plan.yaml` (`source`/`target`/`substitute: true`).
- [x] **T12** [Story: FR-B6-HELM-052] Register `b6-6.test.sh --level 1` in
  `forge-ci.yml`.
- [x] **T13** [Story: FR-B6-HELM-051] Accurate forward-reference wording in
  `infra/README.md.tmpl` + `infra/CLAUDE.md.tmpl` (now point at `infra/k8s/`);
  CHANGELOG `[Unreleased]` entry.

## Verify

- [x] **T14** [Story: NFR-B6-HELM-001] LIVE `helm template` both overlays → exit 0.
- [x] **T15** [Story: NFR-B6-HELM-004] `b6-6.test.sh --level 1,2` GREEN.
- [x] **T16** [Story: NFR-B6-HELM-002, FR-B6-HELM-051] `b6-2.test.sh --level 1,2`
  stays GREEN (bijection + render-clean + Cargo pin untouched).
- [x] **T17** [Story: NFR-B6-HELM-005] Archive once green.
