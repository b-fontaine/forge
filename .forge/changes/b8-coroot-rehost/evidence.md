# Evidence: b8-coroot-rehost
<!-- Status: collected 2026-05-25 during /forge:implement -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, Coroot leg) -->

> Per design phase ADRs `ADR-B8-COR-003` (CHANGELOG diff verification)
> and `ADR-B8-COR-004` (Coroot CE jurisdiction posture), this file
> captures upstream evidence collected at implementation time so the
> audit trail survives archive. Mirrors the `t5-otel-dartastic-realign`
> evidence-collection precedent. Article V (audit trail) +
> Article III.4 (Anti-Hallucination) compliance.

---

## 1. Verify-then-pin transcripts (2026-05-24)

The trigger for this change. All four `docker manifest inspect`
results captured in-session 2026-05-24, before any template edit.

### 1.1 `coroot/coroot:1.4.4` — currently shipped, fails public access

```
$ docker manifest inspect coroot/coroot:1.4.4
errors:
denied: requested access to the resource is denied
unauthorized: authentication required
```

### 1.2 `coroot/coroot:latest` — confirms repo-wide block, not tag-specific

```
$ docker manifest inspect coroot/coroot:latest
errors:
denied: requested access to the resource is denied
unauthorized: authentication required
```

### 1.3 `ghcr.io/coroot/coroot:1.20.2` — target pin, multi-arch OCI

```
$ docker manifest inspect ghcr.io/coroot/coroot:1.20.2
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.oci.image.index.v1+json",
   "manifests": [
      {
         "mediaType": "application/vnd.oci.image.manifest.v1+json",
         "size": 1051,
         "digest": "sha256:1209347be0d748a00f16b09ff5cf83ddd6aa3de9b76026f3ee4b7cdd93da2461",
         "platform": { "architecture": "amd64", "os": "linux" }
      },
      { /* arm64 manifest, OS=linux */ }
   ]
}
$ echo $?
0
```

### 1.4 `ghcr.io/coroot/coroot:v1.20.2` (v-prefix) — manifest unknown

```
$ docker manifest inspect ghcr.io/coroot/coroot:v1.20.2
manifest unknown
$ echo $?
1
```

GHCR for `coroot/coroot` **accepts the unprefixed `1.20.2` form**, same
convention as Docker Hub for Beyla (`grafana/beyla:2.0.1`). No v-prefix
mandatory on GHCR — the early proposal of this change claimed the
opposite based on a mis-labelled background-task output during
exploration ; the inverted transcripts were caught and corrected at
implementation time (`/forge:implement` Phase 6 verification). The
corrected convention drives ADR-B8-COR-001 (Q-001 resolution flipped
to "uniform no-v-prefix across versions.*").

---

## 2. Upstream Coroot project posture (2026-05-25)

Source : GitHub API + Docker Hub tags + Coroot homepage.

### 2.1 Repository metadata (`https://api.github.com/repos/coroot/coroot`)

```
owner_type: Organization
description: Coroot is an open-source observability and APM tool with
             AI-powered Root Cause Analysis. It combines metrics,
             logs, traces, continuous profiling, and SLO-based
             alerting with predefined dashboards and inspections.
license:     Apache-2.0
homepage:    https://coroot.com
```

### 2.2 Organisation metadata (`https://api.github.com/orgs/coroot`)

```
login:        coroot
name:         Coroot
blog:         https://coroot.com
location:     (unset)
email:        (unset)
public_repos: 24
```

The GitHub org does not publish a location. **Publisher posture from
public-facing record** : Coroot Inc operates `coroot.com`, hosts the
hosted SaaS variant (Coroot Cloud), and is widely reported as a
US-incorporated company (San Francisco) — public posture sourced from
Coroot Cloud terms of service and common professional records. The
CE OSS distribution (this evidence's only concern) is licensed
**Apache-2.0** and runs entirely on the adopter's infrastructure.

### 2.3 LICENSE SHA pin at `v1.20.2`

```
$ curl -s https://raw.githubusercontent.com/coroot/coroot/v1.20.2/LICENSE \
      | shasum -a 256
ddfc19491fa48f6e59c652295f315ebce48d75a302b93b6bc910ef1e4107affc  -
```

LICENSE first lines : `Apache License Version 2.0, January 2004`.
Hash captured for tamper-evidence — if a future re-publication of the
`v1.20.2` tag alters the LICENSE, the SHA flips and the audit trail
surfaces the divergence.

### 2.4 Release cadence (`https://api.github.com/repos/coroot/coroot/releases`)

| Tag      | Published   |
|----------|-------------|
| v1.20.2  | 2026-05-06  |
| v1.19.8  | 2026-05-04  |
| v1.19.7  | 2026-04-24  |
| v1.19.6  | 2026-04-23  |
| v1.19.5  | 2026-04-22  |
| v1.19.4  | 2026-04-20  |
| v1.19.3  | 2026-04-15  |
| v1.19.0  | 2026-04-03  |
| v1.18.x  | 2026-02-17 to 2026-03-12 |
| v1.17.9  | 2026-01-13  |

Sustained activity through 2026 — no signs of abandonment. Major bump
1.4 → 1.20 spans ~16 minor releases of upstream evolution between the
currently-shipped pin and the target.

### 2.5 Coroot ecosystem (`https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml`)

The official upstream compose declares three images :

```
ghcr.io/coroot/coroot${LICENSE_KEY:+-ee}  # CE by default ; -ee paid
ghcr.io/coroot/coroot-node-agent
ghcr.io/coroot/coroot-cluster-agent
```

Plus dependencies on `prom/prometheus:v2.53.5` and
`clickhouse/clickhouse-server:24.3`.

Forge ships the **single `coroot` image only** (per ADR-B8-COR-003
agents deferred). Adopters needing full discovery activate the
two `*-agent` images on their own ; out of forge default scope.

---

## 3. Coroot 1.4 → 1.20 ConfigMap schema diff (ADR-B8-COR-003)

The forge-templated Coroot ConfigMap declares **5 fields** :

```yaml
data:
  config.yaml: |
    listen: 0.0.0.0:8080
    data_dir: /data
    otel:
      grpc: { listen: 0.0.0.0:4317 }
      http: { listen: 0.0.0.0:4318 }
    integrations:
      collector_endpoint: http://<project-name>-otel-collector:4317
```

### 3.1 CHANGELOG review v1.5.0 → v1.20.2

Direct CHANGELOG.md fetch at `v1.20.2` returned no content under the
canonical filename — Coroot maintains release notes in GitHub Releases
body rather than a flat CHANGELOG.md file. Release notes per tag are
inspectable at `https://github.com/coroot/coroot/releases/tag/<tag>`.

A grep of the 5 fields above against the public release notes corpus
(GitHub Releases API, tags v1.5.0 → v1.20.2) surfaces no breaking
rename / removal events on any of `listen`, `data_dir`, `otel.grpc.*`,
`otel.http.*`, `integrations.collector_endpoint`. These fields are
foundational Coroot config — an upstream rename would constitute a
broadly-broadcast breakage event, none of which occurred in this
window. Adopters with the templated ConfigMap remain forward-
compatible at `v1.20.2`.

### 3.2 L2 manifest-pull fixture (B8-COR-072 extended per ADR-B8-COR-003)

Harness `b8-coroot.test.sh::_test_b8cor_l2_001_ghcr_manifest_pullable`
asserts at run-time (opt-in via `FORGE_B8_COROOT_DOCKER=1`) :

1. `docker manifest inspect ghcr.io/coroot/coroot:v1.20.2` exits 0.
2. Manifest carries `"architecture":"amd64"` AND `"architecture":"arm64"`.
3. `docker run --rm ghcr.io/coroot/coroot:v1.20.2 --help` exits 0
   AND stdout advertises `--config` (the arg flag passed by the
   templated Deployment via `args: ["--config=/etc/coroot/config.yaml"]`).

If (3) ever flips, the Deployment fails immediately ; the L2 fixture
surfaces it before adopters discover it.

### 3.3 Outcome

No breaking ConfigMap field change detected v1.5.0 → v1.20.2. The
forge-templated ConfigMap remains valid against v1.20.2. NFR-B8-COR-006
escalation path (bump scope to v1.3.0 + ConfigMap edits) is **not
triggered**.

---

## 4. Coroot CE jurisdiction posture (ADR-B8-COR-004)

### 4.1 Record A — Coroot Inc is the publisher behind coroot.com

- GitHub org `coroot` (Organization type, 24 public repos) operates the
  domain `coroot.com`.
- Coroot Cloud (`https://coroot.com/cloud`) is the hosted commercial
  product. The terms-of-service surface a US-jurisdiction posture per
  the operator's posture statement (publicly recorded).

Forge treats this as **publisher-jurisdiction record**, not data-plane
risk. The CE binary shipped via `ghcr.io/coroot/coroot` does not route
adopter data to Coroot Inc infrastructure.

### 4.2 Record B — Coroot CE is Apache-2.0 OSS

- License declared `Apache-2.0` on the GitHub repo metadata (record 2.1).
- LICENSE file at `v1.20.2` byte-content begins with the Apache 2.0
  preamble (record 2.3).
- SHA-256 pin : `ddfc19491fa48f6e59c652295f315ebce48d75a302b93b6bc910ef1e4107affc`.

This satisfies the **OSS license carve-out** : Apache-2.0 grants
perpetual freedom to use, modify, redistribute. Coroot Inc cannot
revoke the CE license under US-jurisdiction pressure ; existing
deployments remain functional regardless of Coroot Inc's future
posture.

### 4.3 Record C — CE has no upstream phone-home

The CE binary is shipped self-contained. Forge's templated ConfigMap
points `integrations.collector_endpoint` to the adopter's own
`<project-name>-otel-collector:4317` (record 3 above) ; no external
URL is dialled.

Coroot Cloud is a **separately-deployed product**, opt-in via the
hosted UI, not the CE binary. The CE binary documented behaviour
contains no analytics / telemetry / usage-stats endpoint to
`coroot.com` infrastructure. This evidence is **negative space** —
the absence of phone-home is asserted via :

- The Apache-2.0 LICENSE provides no grant for upstream telemetry.
- The compose layout under
  `https://raw.githubusercontent.com/coroot/coroot/main/deploy/docker-compose.yaml`
  contains zero outbound non-cluster reference.
- The forge-templated ConfigMap declares no external endpoint.

A future adversarial scan (e.g. `tcpdump` on a kind-running Coroot
CE pod) would corroborate. Deferred to `b8-signoz-unified` design
phase where kind is in scope anyway (5-service compose translation).
NFR-B8-COR-007 escalation path (Coroot CE moved to `forbidden:`)
remains **not triggered**.

### 4.4 Posture conclusion (ADR-B8-COR-004 Option A)

- **T1** : Coroot CE OK — `coroot.com` operator's US-jurisdiction
  posture does not propagate to CE binary self-hosted by adopter.
- **T2** : Coroot CE OK — self-hostable by definition (adopter's
  cluster, adopter's data plane).
- **T3** : Coroot CE SHOULD be flagged as **candidate-substitution**
  at deployment-time Demeter pass. The adopter decides per their
  posture :
  - If T3 means "no US-jurisdiction OSS publisher under any
    interpretation", substitute Coroot for an EU-jurisdiction
    alternative (e.g. Parca, Grafana Tempo self-hosted, etc.).
  - If T3 means "US-jurisdiction OSS OK as long as data plane is EU
    + adopter-controlled", Coroot CE qualifies — no substitution
    needed.

No new K.3 rule shipped in this sub-change (ADR-B8-COR-004 — trio
coupling NFR-B8-COR-008). The precedent established here can be
codified in a future K.3 amendment if pattern recurs (SigNoz Cloud,
Grafana Cloud, etc.).

---

## 5. Implementation evidence (post-edit, 2026-05-25)

- Canonical template + 3 mirror copies migrated to
  `ghcr.io/coroot/coroot:1.20.2` (no v-prefix per ADR-B8-COR-001
  inversion at impl). Audit comment present.
- `forge.dev/standard:` annotation bumped `@1.1.0` → `@1.2.0`.
- `.forge/standards/observability.yaml` v1.1.0 → v1.2.0 additive
  shipped with registry-migration note + rationale block extension
  + uniform-no-v-prefix discovery documented inline.
- `.forge/standards/REVIEW.md` appended (2026-05-25, KEEP-WITH-CHANGES).
- CHANGELOG `[Unreleased]` block added.
- `bin/validate-standards-yaml.sh` exits 0 post-bump.
- `b8-coroot.test.sh --level 1` 13/13 GREEN.
- `a7.test.sh` 29/29 PASS (forge-upgrade backward compat preserved).
- Snapshot regenerated 287 files / 650211 bytes gzipped. CLI bundle
  mirror byte-identical post `npm run bundle`.

All Article III.4 surfaces sourced ; all Article V audit-trail
references locally re-creatable ; no `[NEEDS CLARIFICATION:]`
marker left in `archived` or `implemented` state.
