# Evidence: b8-signoz-unified
<!-- Status: initial collection 2026-05-26 during /forge:propose -->
<!-- Audit: B.8.8 (docs/new-archetypes-plan.md §4.2 — observability rearch, SigNoz leg) -->

> Mirrors the `b8-coroot-rehost/evidence.md` structure. Article V
> (audit trail) + Article III.4 (Anti-Hallucination) compliance.
> Verify-then-pin pass executed by main thread BEFORE proposal
> creation (T5.3.2 lesson institutionalised, see plan §0.5).
> Sections § 5+ reserved for design / implement-phase evidence.

---

## 1. Verify-then-pin pass — 2026-05-26

The trigger for this change. All `docker manifest inspect` results
captured in-session **2026-05-26**, before any template edit. Run by
main thread per the institutionalised T5.3.2 verify-then-pin
discipline.

### 1.1 `signoz/signoz:v0.125.1` — target unified pin, multi-arch

```
$ docker manifest inspect signoz/signoz:v0.125.1
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
   "manifests": [
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "digest": "sha256:e56541a2770632c8630c1bd32b6b57c43a8cfdcdfec85018eae410313dc70613",
         "platform": { "architecture": "amd64", "os": "linux" }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "digest": "sha256:f2e0ce661687e0dcab16df8dc7e1dc3c7041d7c41846b0274bb38ac68b509419",
         "platform": { "architecture": "arm64", "os": "linux" }
      }
   ]
}
$ echo $?
0
```

### 1.2 `signoz/signoz-otel-collector:v0.144.4` — target collector pin, multi-arch

```
$ docker manifest inspect signoz/signoz-otel-collector:v0.144.4
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
   "manifests": [
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "digest": "sha256:9b2cc1a07772a703ec03f098130fca9baf097a0d24f18b2357cc3b52855a1a8d",
         "platform": { "architecture": "amd64", "os": "linux" }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "digest": "sha256:42727e4be83e85257f4d4d336d7c2a63c25a7d25e08d6be8c69aa521efff7950",
         "platform": { "architecture": "arm64", "os": "linux" }
      }
   ]
}
$ echo $?
0
```

### 1.3 Docker Hub tag listing (ordering=last_updated) — 2026-05-26

| Repository                          | Latest tag  | Published    |
|-------------------------------------|-------------|--------------|
| `signoz/signoz`                     | `v0.125.1`  | 2026-05-20   |
| `signoz/signoz-otel-collector`      | `v0.144.4`  | 2026-05-06   |

Both pins are the most-recent published tags at the verify-then-pin
timestamp. Neither has a `latest` floating tag pinned to the same
SHA (forge policy avoids `latest` per Article VIII determinism).

### 1.4 Tag convention — **v-prefix uniformly across SigNoz repositories**

SigNoz upstream uses **v-prefix** on both repositories' tags :
- `signoz/signoz` → `v0.125.1` (not `0.125.1`)
- `signoz/signoz-otel-collector` → `v0.144.4` (not `0.144.4`)

This is **opposite of** `coroot/coroot` and `grafana/beyla` (which drop
the v-prefix and accept the unprefixed form on Docker Hub).

**Documented inline to prevent the `b8-coroot-rehost` ADR-B8-COR-001
inversion-at-impl pattern recurrence.** The b8-coroot-rehost initial
proposal mis-read GHCR convention as v-prefix-mandatory ; the true
convention for `ghcr.io/coroot/coroot` is unprefixed. The mis-read was
caught only at `/forge:implement` Phase 6 by the L2 manifest-pull
fixture. To avoid recurrence on the SigNoz leg :

- The verify-then-pin pass for SigNoz was executed at **propose time**
  (not implement time) by the main thread.
- Both `v0.125.1` (prefixed) and `0.125.1` (unprefixed) were tested ;
  only the prefixed form returns a valid manifest.
- The convention difference vs Coroot/Beyla is documented here in
  evidence.md § 1.4 and will be cross-referenced in `observability.yaml`
  v2.0.0 inline comment block, in `proposal.md` § Constitution III.4,
  and in the design.md ADR resolving Q-001.

### 1.5 Rotted 3-service pins — confirmation (delta against §0 plan claim)

Per `docs/new-archetypes-plan.md` §0.5 the old 3-service pins
(`signoz/frontend:0.55.1`, `signoz/query-service:0.55.1`, last published
`0.76.3`) were pruned from Docker Hub. This evidence section reserves
the verbatim `docker manifest inspect` capture for the rotted pins ;
to be filled at `/forge:design` if upstream still serves any of the
old tags for read-only inspection. The trigger for this change does
not depend on the rotted-pin evidence — `task validate dev-up-matrix`
RED is the empirical failure signal, ratified as known-issue for
v0.4.0-rc.2 and v0.4.0-rc.3 already.

---

## 2. Verify-then-implement pass — 2026-05-27 (/forge:implement, Atlas)

Re-run of the four `docker manifest inspect` pins LIVE at implement
time per the b8_coroot lesson (verify-then-pin must run live at
`/forge:implement`, not trust the propose/design transcripts). All
four exit 0, all multi-arch (amd64 + arm64), all digests **byte-identical
to the propose/design-time captures** (§ 1.1 + § 1.2 + design EV-5). No
pin rotted between 2026-05-26 and 2026-05-27 — NO STOP condition.
`docker` present on PATH (`Docker version 29.4.3`), so this is a live
run, not a skip-pass.

### 2.1 `signoz/signoz:v0.125.1` (T-PRE-001) — exit 0, multi-arch

```
$ docker manifest inspect signoz/signoz:v0.125.1
manifest list v2 :
  amd64  sha256:e56541a2770632c8630c1bd32b6b57c43a8cfdcdfec85018eae410313dc70613
  arm64  sha256:f2e0ce661687e0dcab16df8dc7e1dc3c7041d7c41846b0274bb38ac68b509419
EXIT=0
```

Digests MATCH § 1.1 (propose-time) exactly. ✅

### 2.2 `signoz/signoz-otel-collector:v0.144.4` (T-PRE-002) — exit 0, multi-arch

```
$ docker manifest inspect signoz/signoz-otel-collector:v0.144.4
manifest list v2 :
  amd64  sha256:9b2cc1a07772a703ec03f098130fca9baf097a0d24f18b2357cc3b52855a1a8d
  arm64  sha256:42727e4be83e85257f4d4d336d7c2a63c25a7d25e08d6be8c69aa521efff7950
EXIT=0
```

Digests MATCH § 1.2 (propose-time) exactly. ✅

### 2.3 `clickhouse/clickhouse-server:25.5.6` (T-PRE-003) — exit 0, multi-arch

```
$ docker manifest inspect clickhouse/clickhouse-server:25.5.6
OCI image index v1 :
  amd64    sha256:5dcbe5f00521c32f4db29a9e804366ea34544be92b85b075d05b4f1572fef83f
  arm64    sha256:03c712ef372eb30e5fdefca184b0ff54ff5bea5456638ea349f42fbfcd4043f9
  unknown  sha256:39951a03e4a1316876b77b00f8e3b5f2c7e09b56ef376640a5f106c6c425d2cf  (buildx attestation)
  unknown  sha256:b37b99107303a332904fc34cb31213ee018268dcb5d51baf2a7d9c406b5cafc6  (buildx attestation)
EXIT=0
```

amd64 + arm64 digests MATCH design EV-5 exactly. The two extra
`unknown/unknown` entries are standard buildx provenance/SBOM
attestation manifests, not runtime platforms — they do not affect the
multi-arch invariant. ✅

### 2.4 `signoz/zookeeper:3.7.1` (T-PRE-004) — exit 0, multi-arch

```
$ docker manifest inspect signoz/zookeeper:3.7.1
manifest list v2 :
  amd64  sha256:1e6c92e8656c299818acfaf72f11e59d68a92bfe39fc1b1137cd78d6ab6741aa
  arm64  sha256:a123eae294ce9c2e32b84d32b2af83e7661d54631430cea376c53ada373d26d9
EXIT=0
```

Digests MATCH design EV-5 exactly. ✅

### 2.5 Rotted-pin invariant re-confirmed (T-L2-006 backing)

```
$ docker manifest inspect signoz/frontend:0.55.1       → "no such manifest" (FAIL, expected)
$ docker manifest inspect signoz/query-service:0.55.1  → "no such manifest" (FAIL, expected)
```

The verify-then-pin invariant holds : the rotted 3-service pins remain
unpullable from Docker Hub. The rehost rationale is intact. ✅

---

## 2-design. Upstream SigNoz project posture (design-phase, superseded by ADRs)

The design-phase Demeter pass + upstream Compose fetch are captured in
`design.md` § Evidence Source Notes (EV-1..EV-6) and resolved into
ADR-B8-SIG-001..007. Not duplicated here.

---

## 3. Mirror inventory enumeration — 2026-05-27 (T-PRE-006)

Resolves the spec `Q-001-adjacent` mirror-inventory `[NEEDS CLARIFICATION]`
(FR-B8-SIG-G-005). Enumerated live :

```
$ find . -path ./node_modules -prune -o -name 'docker-compose*.yml*' -print | grep -v node_modules
./examples/forge-fsm-example/docker-compose.dev.yml
./.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl
./cli/assets/examples/forge-fsm-example/docker-compose.dev.yml
./examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl
./cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl
./cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl
```

**6 copies confirmed** — matches Implementer Note 4 exactly. NO `1.0.0/infra/`
path segment ; canonical lives directly under `full-stack-monorepo/`. No 7th
copy. The 6 split into 3 `.tmpl` pairs and the rendered-example pair :

| Constant | Path | Kind |
|---|---|---|
| `SIG_CANONICAL` | `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` | canonical .tmpl (source of truth) |
| `SIG_CLI_TMPL` | `cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` | cli-bundle .tmpl mirror |
| `SIG_EXAMPLE_TMPL` | `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` | example-side .tmpl variant |
| `SIG_CLI_EXAMPLE_TMPL` | `cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` | cli-bundle of the example-side .tmpl |
| `SIG_EXAMPLE` | `examples/forge-fsm-example/docker-compose.dev.yml` | rendered example |
| `SIG_CLI_EXAMPLE` | `cli/assets/examples/forge-fsm-example/docker-compose.dev.yml` | cli-bundle rendered mirror |

### 3.1 forge-ci.yml budget pre-check (T-PRE-005)

```
$ wc -l .github/workflows/forge-ci.yml  → 297
```

297 + 3-line matrix entry = 300 exactly = NFR-CI-002 ceiling. No comment
compression required (headroom confirmed). ✅

### 3.2 Snapshot baseline size (T-SNP-003 pre-condition)

```
$ ls -la .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz  → 635.0K
```

**Pre-existing overage.** The snapshot on `main` is already 635 KB,
ALREADY over the NFR-B8-SIG-001 / NFR-OTEL-001 600 KB budget — BEFORE this
change. The overage is dominated by framework scripts/docs inside the
snapshot (constitution-linter 47 KB, delivery.test 42 KB, ARCHITECTURE-TARGET
90 KB, etc.), NOT by the docker-compose template (which the unified rewrite
grows by only ~30-40 lines ≈ < 1 KB gzipped). This change does not cause the
overage and cannot resolve it (the budget breach is a separate framework-wide
concern). T-SNP-003 is reported honestly as a pre-existing RED, not silently
passed. See § 5 implement evidence for the post-regen number.

---

## 4. SigNoz CE jurisdiction posture (reserved for /forge:design ADR-6)

Reserved for the design-phase Demeter K3-RULE classification. Will
mirror `b8-coroot-rehost/evidence.md` § 4 structure :

- 4.1 Record A — SigNoz Inc publisher record
- 4.2 Record B — SigNoz CE LICENSE inspection
- 4.3 Record C — CE binary phone-home audit
- 4.4 Posture conclusion (T1/T2 vs T3 classification, K.3 rule
       impact, resolves Q-006)

---

## 5. Implementation evidence — 2026-05-27 (/forge:implement, Atlas)

### 5.1 Deliverables shipped

- **6 docker-compose copies** carry the unified 6-service arch (4
  long-running + 2 init) + the 4 pins `signoz/signoz:v0.125.1` +
  `signoz/signoz-otel-collector:v0.144.4` + `clickhouse/clickhouse-server:25.5.6`
  + `signoz/zookeeper:3.7.1`. Byte-identity verified by L1 test 017 + `diff -q`
  on the 3 `.tmpl` pairs + the rendered-example pair.
- **`observability.yaml` v1.2.0 → v2.0.0 BREAKING** : versions surgery (4 ADD,
  0 legacy keys), `breaking_change: true`, top-level `pin_review_cadence:`
  (ISO 8601 P30D/P12M), WAIVER block citing **ADR-J7-004** (Implementer Note 2),
  `last_reviewed: 2026-05-26`, `expires_at: 2027-05-26`, rationale extended
  with ADR-006 jurisdiction, beyla reserved-scope comment. `versions.beyla`
  UNCHANGED (NFR-B8-SIG-011). `forbidden:` + `linter_rule: null` UNCHANGED.
- **`REVIEW.md`** ARCH-CHANGE H2 section appended (2026-05-26, table row
  `| observability.yaml | 2.0.0 | ARCH-CHANGE | 2027-05-26 |`).
- **CHANGELOG.md** `[Unreleased]` dedicated `### Fixed` block added.
- **`infra/CLAUDE.md.tmpl`** SigNoz unified H2 section added (6-svc layout, UI
  port ADR-004, OPAMP-off ADR-003, fresh-start posture, jurisdiction ADR-006,
  v-prefix, ADR-J7-004 citation).
- **`docs/new-archetypes-plan.md`** : ARCH-CHANGE precedent paragraph
  (FR-B8-SIG-H-006) + inventory row. **`roadmap.md`** T6 B.8.8 SigNoz-leg entry.
- **`forge-ci.yml`** matrix +1 (`b8-signoz.test.sh --level 1`), 300/300 lines.
- **New harness** `.forge/scripts/tests/b8-signoz.test.sh` (17 L1 + 6 L2).
- **Snapshot** regenerated → `cli/assets` mirror byte-identical.
- **`standard.schema.json` UNCHANGED** (ADR-005 / ADR-J7-004 schema-tolerate).

### 5.2 Config files added to realize the boot chain (ADR-001 / ADR-003)

The 82-task plan assumed env-vars alone suffice for the collector + migrator
(design ADR-003 "static config via env"). Live L2 compose-up revealed two
config-file dependencies that upstream EV-1 mounts and the simplified template
initially omitted. Both fixed with upstream-verbatim values (Article III.4 —
fetched live 2026-05-27, NOT invented) :

1. **ClickHouse `cluster.xml`** — the migrator's `ON CLUSTER cluster` DDL needs
   a `cluster` named cluster. Realized via `init-clickhouse` (ADR-001 "copies
   cluster bootstrap files") writing a minimal single-node `cluster.xml`
   (remote_servers + zookeeper node + macros) into a shared `signoz-clickhouse-config`
   volume mounted at ClickHouse `config.d/`. Verified : `SELECT cluster FROM
   system.clusters WHERE cluster='cluster'` → `cluster` ; migrator runs through
   `migration_id 1006` exit 0.
2. **`signoz-otel-collector-config.yaml`** — the collector binary needs
   `--config=<file>` (without it, defaults to `localhost:9000` → connection
   refused). Shipped `infra/observability/signoz-otel-collector-config.yaml.tmpl`
   verbatim from upstream v0.125.1 `deploy/docker/otel-collector-config.yaml`
   (only the ClickHouse host changed `clickhouse` → `fsm-signoz-clickhouse`).
   Collector invoked `migrate sync check && --config=...` (OPAMP-off, NO
   `--manager-config` per ADR-003).

Also fixed (live-verified) :
- **Zookeeper healthcheck** : `ruok` 4lw is whitelist-gated in
  `signoz/zookeeper:3.7.1` → switched to `zkServer.sh status` (works standalone).
- **Migrator command** : the initial guessed `--dsn=` flag was a hallucination
  (`unknown flag: --dsn`) → replaced with the verbatim upstream
  `/signoz-otel-collector migrate {bootstrap,sync up,async up}` invocation.
- **Collector healthcheck removed** : the `signoz/signoz-otel-collector` image
  is minimal (no wget/curl/nc ; `sh` has no `/dev/tcp`), so no in-container HTTP
  probe is possible. Matches upstream EV-1 (collector has no healthcheck). The
  collector keeps `restart: unless-stopped` ; readiness gated by depends_on.

### 5.3 Test results (live, docker present — NOT skip-passed)

- `b8-signoz.test.sh --level 1` : **17/17 L1 PASS**, ≤ 2 s.
- `FORGE_B8_SIGNOZ_DOCKER=1 b8-signoz.test.sh --level 1,2` : **23/23 PASS**
  (17 L1 + 6 L2). L2 ran LIVE : 4 manifests multi-arch pullable + compose-up
  reached convergence (zookeeper + clickhouse + signoz `healthy`, collector
  `running`, migrator completed) + rotted 3-svc pins denied. NOT skip-passed.
- `a7.test.sh` : **29/29 PASS** (forge-upgrade compat preserved across the
  breaking bump).
- `validate-standards-yaml.sh observability.yaml` : exit 0.
- `verify.sh` : 288 PASS / 0 FAIL / 1 WARN → PASS.
- `validate-change-yaml.sh` : exit 0.

### 5.4 Snapshot size (T-SNP-003) — honest report

Post-regen snapshot : **~647 KB** gzipped, OVER the 600 KB NFR-B8-SIG-001
budget. **Pre-existing overage** : `main` was already 635 KB before this change
(§ 3.2). This change adds ~12 KB (unified compose + new collector config +
standard/REVIEW growth). The budget breach is framework-wide (dominated by
scripts/docs in the snapshot) and is NOT resolvable within this change's scope.
Reported, not silently passed.

### 5.5 Determinism (T-SNP-002) — deviation note

The real `bin/forge-snapshot.sh` uses `build <archetype> <version>` and does
NOT support `SOURCE_DATE_EPOCH` (the task's assumed invocation). Its
determinism contract (per the script + A.7 ADR-004) is **per-file content SHA**,
which IS deterministic (verified : two rebuilds → per-file content identical,
`diff -r` clean). The gzip tarball itself is not byte-identical across rebuilds
(gzip embeds mtime), but A.7's 3-way merge consumes per-file SHA, so the
FR-B8-SIG-D-002 intent holds at the level that matters.

### 5.6 Open items for the independent reviewer (T-REV-001)

1. **constitution-linter FAIL (3 violations)** — `proposal.md:56/58/60` bare
   `[NEEDS CLARIFICATION:]` markers. The Article III.4 linter rule "no
   NEEDS CLARIFICATION in implemented/archived" fires once status flips to
   `implemented`. The markers ARE resolved (Q-001/002/003 → ADR-B8-SIG-001/002/003).
   The executor brief forbids editing the frozen `proposal.md`. b8-coroot avoided
   this by wrapping its single marker in a code-span (linter-tolerated). RESOLUTION
   NEEDED : either an Article V exception to code-span-wrap the 3 resolved markers
   in proposal.md, or a maintainer ruling. NOT fixed by the executor (frozen-file
   constraint).
2. **`task validate dev-up-matrix` still RED — but on KONG, not SigNoz.** The
   SigNoz stack boots clean (L2 23/23 GREEN). `task dev:up` now fails at
   `kong:3.6-alpine` (`manifest unknown` — Kong pin rotted on Docker Hub).
   Kong is EXPLICITLY out of scope per proposal Scope Out ("Kong stays … 3.6-alpine
   GONE … Kong leg = future B.8.x change, defer"). So NFR-B8-SIG-007 is
   PARTIALLY met : the SigNoz contribution to the dev-up-matrix RED is resolved
   (proven via L2 compose-up), but a separate deferred component (Kong) keeps the
   end-to-end leg RED.
3. **b8-coroot.test.sh regression** — the shared-standard v2.0.0/2026-05-26 bump
   flips `_test_b8cor_l1_008_standard_version_bumped` (pins `version: "1.2.0"`)
   and `_test_b8cor_l1_010_standard_last_reviewed_today` (pins `2026-05-2[45]`)
   from GREEN to RED. These framework-owned live harness assertions hard-pin the
   prior trio state. design.md ADR-005 analyzed only the `versions:` *shape*
   (test 009 stays GREEN) and missed tests 008/010. t5-otel.test.sh tests 021/080
   were ALREADY RED on main from b8-coroot's own bump (not this change's
   regression). NOT fixed by the executor (no task authorizes editing a sibling
   harness ; reviewer/maintainer decision).

### 5.7 Post-review reconciliation (2026-05-27, maintainer-ruled)

Independent code-reviewer pass re-executed every gate from scratch (not
trusting this transcript). Verdict: implementation fabrication-free (4 pins
re-inspected live, 8 digests match §2 ; collector config byte-identical to
upstream SigNoz v0.125.1 except the documented ClickHouse host ; 6-copy mirror
synced ; ISO 8601 cadence + ADR-J7-004 WAIVER citation + unchanged
`standard.schema.json` all confirmed ; Article V freeze holds). Two CI-blocking
issues + one pre-existing escape resolved under maintainer rulings:

1. **proposal.md markers (linter exit 1)** — RULED: backtick-wrap. The 3
   resolved `[NEEDS CLARIFICATION:]` markers at proposal.md:56/58/60 are now
   code-span-wrapped (linter-tolerated, text verbatim). Mirrors b8-coroot's
   v-prefix-correction precedent. `constitution-linter.sh` → 43 PASS / 0 FAIL.

2. **b8-coroot.test.sh 008/010 regression** — RULED: update assertions. As trio
   owner of the v2.0.0 bump, b8-signoz-unified updates the sibling harness
   (shared CI file, outside any archived change dir — no Article V breach):
   test 008 tracks `version "2.0.0"`, test 010 accepts `last_reviewed
   2026-05-2[67]`. Comments document the trio progression for the b8-obi-refresh
   author. b8-coroot.test.sh → 13/13 GREEN.

3. **t5-otel.test.sh 021/080 (PRE-EXISTING main-CI-red escape)** — RULED: narrow
   now. b8-coroot-rehost archived + shipped as v0.4.0-rc.3 with these two sibling
   assertions left RED (it bumped the standard + coroot template without updating
   t5-otel.test.sh). Confirmed via `git show HEAD:.forge/standards/observability.yaml`
   (committed main = v1.2.0 + coroot 1.20.2, both ≠ the test's hard-pinned 1.1.0 /
   1.4.4). Fix: test 021 tracks `ghcr.io/coroot/coroot:1.20.2` ; test 080 NARROWED
   to t5-otel-stack's own persistent deliverables (beyla 2.0.1 + append-only
   REVIEW.md v1.1.0 birth row), dropping the mutable whole-file `version:` +
   `versions.coroot` assertions now owned by the trio harnesses. Robust to future
   trio legs. t5-otel.test.sh → 14/14 GREEN.

Kong (`kong:3.6-alpine` rotted) stays out of scope per proposal Scope Out —
`task validate dev-up-matrix` end-to-end still gated by the deferred Kong leg
(separate future B.8.x change), but the SigNoz contribution to that RED is
resolved (L2 23/23 compose-up live). Snapshot 647 KB overage is pre-existing
framework-wide debt, not introduced here.

---

## 6. Post-review budget bump + Aegis/verifier fixes — 2026-05-27 (maintainer-ruled)

The re-review (code-reviewer + Aegis + verifier) surfaced six fixes. The
archive-blocker was the snapshot exceeding the CI-enforced size ceiling.

### 6.1 Snapshot budget bump (FIX 1 / ADR-B8-SIG-008)

```
$ wc -c .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
664855
$ git show HEAD:.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz | wc -c   # main, pre-change
650211
```

- **Measured snapshot** : **664855 B** (regenerated post FIX 2/3/4 template
  edits — see § 6.5 for the post-regen number).
- **Prior ceiling** (`t5.test.sh::_test_t5_024`) : **655360 B** (640 KiB).
- **New ceiling** : **716800 B** (700 KiB) — ~52 KB headroom for the
  `b8-obi-refresh` trio leg.
- **Maintainer ruling** : **bump, not trim**. The growth is legitimate
  unified-arch functional content (6-service compose + new collector config +
  refreshed SigNoz CLAUDE.md doc), not bloat. Trimming to fit an aspirational
  600 KB would remove real scaffold files or break the per-file SHA contract.
- **Supersession note** : the frozen **specs.md NFR-B8-SIG-001 "≤ 600 KB"**
  text stays per **Article V** (no edits in the frozen spec). It was
  **already silently violated on `main`** (HEAD snapshot = 650211 B, > 600 KB,
  before this change). The enforced gate has been `_test_t5_024`'s threshold,
  not the 600 KB prose. **ADR-B8-SIG-008** supersedes the 600 KB figure with
  the 700 KiB CI ceiling — same supersession pattern as the
  **ADR-J7-008 → ADR-J7-004** citation correction (frozen text left intact,
  correction carried in the design ADR).

### 6.2 Aegis HIGH — prod-hardening delta doc (FIX 2)

`infra/CLAUDE.md.tmpl` gained an `### Production hardening delta` subsection
under the SigNoz section, enumerating the 5 dev-only deltas Aegis flagged
(default-user ClickHouse no-password, anonymous Zookeeper, no TLS, no UI auth
gate, host-published ports). Mirrors the existing OBI-DaemonSet + Coroot
prod-warning sections' tone.

### 6.3 Aegis HIGH — loopback-bind host-published ports (FIX 3)

Canonical compose host publishes changed `0.0.0.0` → `127.0.0.1` loopback for
the OTLP collector (`4317` + `4318`), the SigNoz UI
(`${SIGNOZ_UI_PORT:-3301}:8080`), and Kong proxy (`8000`). Internal-only
services (ClickHouse, Zookeeper) have no ports block — left untouched. An audit
comment documents loopback-bind as the dev posture (prod uses ingress per FIX 2).

### 6.4 Aegis MEDIUM — SigNoz CE phone-home opt-out (FIX 4) — env var DOES NOT EXIST for v0.125.1

**Upstream fetch (Article III.4 — fetched live 2026-05-27, NOT guessed)** :

| Source | URL | Finding |
|---|---|---|
| Upstream v0.125.1 compose | `https://raw.githubusercontent.com/SigNoz/signoz/v0.125.1/deploy/docker/docker-compose.yaml` | `signoz` service sets NO telemetry opt-out env var. Env vars present: `SIGNOZ_ALERTMANAGER_PROVIDER`, `SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN`, `SIGNOZ_SQLSTORE_SQLITE_PATH`, `SIGNOZ_TOKENIZER_JWT_SECRET`. |
| SigNoz telemetry docs | `https://signoz.io/docs/telemetry/` | Current opt-out is the **config-file key `statsreporter.enabled: false`** (defaults `true`). The legacy `TELEMETRY_ENABLED` env var **was removed in versions > 0.87.0**. |
| SigNoz config example | `https://github.com/SigNoz/signoz/blob/main/conf/example.yaml` | `statsreporter:` block in `config.yaml`. |

**Conclusion** : there is **NO environment variable** to disable the usage
beacon on `signoz/signoz:v0.125.1`. The pre-existing doc/standard claim of
"no upstream phone-home" was **overstated for T3**. `TELEMETRY_ENABLED=false`
would be a **no-op hallucination** on v0.125.1 (env var removed > 0.87.0). The
real opt-out is the `statsreporter.enabled: false` **config-file** key, which
requires mounting a `signoz` `config.yaml` — an out-of-scope template expansion
for this change.

**Resolution (honesty over fabricated env)** : NO guessed env added. Instead
the `observability.yaml::rationale` + `infra/CLAUDE.md.tmpl` jurisdiction note
are **qualified** : "CE usage beacon is ON by default on the unified image ;
T3 adopters MUST disable it via `statsreporter.enabled: false` (see SigNoz
docs)". The unresolved config-file-mount scope is tracked as **Q-007** in
`open-questions.md`.

### 6.5 Mirror sync + snapshot regen (post FIX 2/3/4 edits)

```
$ cd cli && npm run bundle    # regen cli/assets .tmpl + rendered + snapshot mirrors
$ wc -c .forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz \
        cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz
<final post-regen size — see report>  (both byte-identical mirrors)
```

Final snapshot size after FIX 2/3/4 template edits + regen is recorded in the
post-fix gate sweep ; it remains **< 716800 B** (the new `_test_t5_024`
ceiling), so `_test_t5_024` is GREEN.
