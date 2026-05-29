# Open Questions — b8-obi-refresh

<!--
Tracks unresolved questions per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`). Q-NNN is sequential
per change, zero-padded to 3 digits, never reused.
-->

## Q-001: Final target Beyla tag on Docker Hub

- **Status**: answered
- **Raised in**: `.forge/changes/b8-obi-refresh/proposal.md` + `specs.md` FR-B8-OBI-001
- **Raised on**: 2026-05-29
- **Raised by**: maintainer (b8-obi-refresh propose pass)

### Question

The proposal targets `grafana/beyla:3.15.0` as the bump destination.
Verify-then-pin discipline mandates live confirmation via
`docker manifest inspect grafana/beyla:3.15.0` before freezing the
pin.

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: pin `grafana/beyla:3.15.0`. See **ADR-B8-OBI-001** in
  `design.md` + `evidence.md` § 1 for the live `docker manifest
  inspect` transcript (multi-arch amd64+arm64, digests captured).
- **Authority**: live Docker Hub manifest 2026-05-29 returned a valid
  OCI image index with 2 platform manifests (amd64 / arm64) + 2
  attestation manifests (`unknown/unknown`, cosign / SLSA).

---

## Q-002: Beyla 3.x Linux capability set delta vs 2.x

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-OBI-060 + ADR-B8-OBI-002
- **Raised on**: 2026-05-29

### Question

Beyla 3.x may have refined the cap requirements vs 2.x : tighten,
keep, or widen the 8-cap `add:` list ?

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **UNCHANGED** — preserve the 8-cap set verbatim
  (`BPF`, `SYS_PTRACE`, `NET_RAW`, `CHECKPOINT_RESTORE`,
  `DAC_READ_SEARCH`, `PERFMON`, `NET_ADMIN`, `SYS_ADMIN`). See
  **ADR-B8-OBI-002** + `evidence.md` § 2 (Context7
  `/grafana/beyla` distributed-traces.md snippet).
- **Authority**: Beyla 3.x docs ship two snippets — a 6-cap
  "unprivileged-minimal" (without NET_ADMIN/SYS_ADMIN) AND an 8-cap
  "distributed-traces". The Forge flagship enables W3C `traceparent`
  E2E propagation (`t5-otel-traceparent-e2e`), requiring NET_ADMIN ;
  SYS_ADMIN remains recommended for richer Go/Rust language
  introspection.

---

## Q-003: Beyla 3.x RBAC delta vs 2.x

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-OBI-063 + ADR-B8-OBI-003
- **Raised on**: 2026-05-29

### Question

Beyla 3.x may require new API groups beyond `{pods, nodes,
replicasets}`.

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **WIDEN** ClusterRole — add `services` resource (read-
  only `get/list/watch`, apiGroup `""`). See **ADR-B8-OBI-003** +
  `evidence.md` § 3 (Context7 `/grafana/beyla` cilium-compatibility.md
  RBAC snippet).
- **Authority**: Beyla 3.x official RBAC YAML grants `services` on
  top of `pods, nodes` (apiGroup `""`) + `replicasets` (apiGroup
  `apps`). The widening is read-only (`list, watch` per Beyla docs ;
  Forge preserves the additional `get` verb already granted to other
  resources for harness symmetry). No write verbs introduced ; Aegis
  least-privilege invariant preserved.

---

## Q-004: Beyla 3.x minimum kernel — keep `kernel-min-58` nodeSelector ?

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-OBI-064 + ADR-B8-OBI-004
- **Raised on**: 2026-05-29

### Question

Beyla 3.x may have lifted its minimum kernel requirement from 5.8 to
6.x.

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **UNCHANGED** — preserve
  `nodeSelector.forge.dev/kernel-min-58: "true"` verbatim. See
  **ADR-B8-OBI-004** + `evidence.md` § 4 (Beyla 3.x README
  Requirements section).
- **Authority**: Beyla 3.x README still declares "Linux kernel
  version 5.8 or higher with BTF enabled" as the minimum (RHEL
  4.18 + backports also supported). No kernel-floor lift. Adopters
  who labelled nodes with the current opt-in label keep them ; zero
  migration burden.

---

## Q-005: Mirror copy count — 4 or 6 ?

- **Status**: answered
- **Raised in**: `proposal.md` step 5 + `specs.md` FR-B8-OBI-007 + ADR-B8-OBI-005
- **Raised on**: 2026-05-29

### Question

Coroot leg (4-copy) vs SigNoz leg (6-copy) precedents. Need exact
enumeration for `obi-daemonset.yaml*`.

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **4 copies** — see **ADR-B8-OBI-005** + `evidence.md`
  § 5 (`find` enumeration 2026-05-29).
- **Authority** : `find . -type f \( -name '*obi*' -o -name
  '*beyla*' \) -not -path '*/node_modules/*' -not -path '*/.git/*'`
  returned exactly 4 paths matching the `obi-daemonset` glob :
  canonical `.tmpl`, cli-bundle `.tmpl`, rendered example, cli-bundle
  rendered. No `examples/forge-fsm-example/.forge/templates/...`
  mirror exists for OBI (unlike `docker-compose.dev.yml.tmpl`).

---

## Q-006: Sibling-harness narrowing strategy

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-OBI-080..086 + ADR-B8-OBI-006
- **Raised on**: 2026-05-29

### Question

`t5-otel.test.sh` hard-pins `grafana/beyla:2.0.1` (lines 128, 233).
`b8-coroot.test.sh::_test_010` and `b8-signoz.test.sh::_test_010`
hard-pin `last_reviewed:` dates. Strategy : bump, narrow, or hybrid ?

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **hybrid** (option c) — see **ADR-B8-OBI-006**.
  Narrow `t5-otel.test.sh:128/233` (transfer pin ownership to
  `b8-obi.test.sh` ; t5-otel asserts only the no-`:latest` invariant
  + `versions.beyla:` key existence). Widen
  `b8-coroot.test.sh:196` date regex `2026-05-2[67]` →
  `2026-05-2[6789]` and `b8-signoz.test.sh:295` exact
  `2026-05-26` → `2026-05-2[6789]` (1-char widening).
- **Authority**: mémoire `shared_standard_sibling_harness_coupling.md`
  (institutionalised post-`b8-signoz-unified`) mandates breaking
  coupling chains. Hybrid balances cost (4 sibling edits, 2 narrow
  + 2 widen) against perpetual-churn avoidance.

---

## Q-007: `forge-ci.yml` line budget freeing strategy

- **Status**: answered
- **Raised in**: `specs.md` FR-B8-OBI-121 + ADR-B8-OBI-007
- **Raised on**: 2026-05-29

### Question

`forge-ci.yml` is 300/300 lines (NFR-CI-002 plafond). Need ≥ 1 free
line to register `b8-obi.test.sh` in the matrix.

### Resolution

- **Resolved on**: 2026-05-29
- **Decision**: **comment compression** (option a) — see
  **ADR-B8-OBI-007**. Mirror `ADR-T533-002` (T5.3.3) verbatim. NO
  plafond lift ; NFR-CI-002 held at ≤ 300.
- **Authority**: `wc -l .github/workflows/forge-ci.yml` = 300/300
  confirmed 2026-05-29. Comment compression pattern documented at
  `t5-3-3-vitest-bundle-preflight::ADR-T533-002` ; reuse pattern
  verbatim. Diff captured to `evidence.md` § ci-compression at
  `/forge:implement`.
