# Specifications: b1-1-dev-up-matrix-fixes
<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: T5.3.1 (docs/new-archetypes-plan.md §0.4) -->

**Namespace** : `FR-B1-DUM-*` / `NFR-B1-DUM-*` / `ADR-B1-DUM-*`.
**Constitution** : v1.1.0, unchanged. **Article II** : N/A — pure
template hygiene, no user-facing feature.

## Source Documents

| Field                      | Value                                                                                                                                              |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| **Plan ref**               | `docs/new-archetypes-plan.md` §0.4 (`b1-1-dev-up-matrix-fixes` planned 2026-05-18)                                                                  |
| **Originating bug 1**      | `docker-compose.dev.yml.tmpl:60` declares `image: scratch` — Docker rejects reserved name → `task dev:up` fails on `fsm-backend`                    |
| **Originating bug 2**      | `docker-compose.dev.yml.tmpl:25` declares `version: "3.8"` — Compose v2 emits `WARN[0000] the attribute version is obsolete`                        |
| **Template (canonical)**   | `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`                                                                       |
| **Template (mirror 1)**    | `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`                                            |
| **Template (mirror 2)**    | `cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`                                                            |
| **Template (mirror 3)**    | `cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`                                 |
| **Smoke driver**           | `Taskfile.yml::dev-up-matrix` (currently the only level that exercises `docker compose up`)                                                         |
| **E2E candidate**          | `cli/test/e2e/archetypes-smoke.test.ts` (no Docker today)                                                                                           |
| **Upstream dep**           | `t5-otel-dartastic-realign` (archived 2026-05-18) greened `smoke-with-toolchains` so `dev-up-matrix` is reachable                                   |
| **Release target**         | v0.4.0-rc.1 piggyback OR v0.4.0-rc.2 patch (decision deferred to release time per proposal)                                                         |
| **Harness frame**          | `_helpers.sh` + `--level` parsing pattern from `t5-2.test.sh` / `t5-bin-server.test.sh`                                                              |
| **CI matrix budget**       | `.github/workflows/forge-ci.yml` currently 296 lines ; NFR-CI-002 ≤ 300 → +4 line headroom for the new matrix entry                                 |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — `image: scratch` placeholder fix (FR-B1-DUM-001 → 010)

##### FR-B1-DUM-001 — `image: scratch` removed from canonical template

`.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl::fsm-backend`
MUST NOT declare `image: scratch`.

##### FR-B1-DUM-002 — Replacement strategy is functional

The replacement for `image: scratch` MUST allow `task dev:up` to
reach a steady state on a fresh scaffold without manual editing of
the rendered `docker-compose.dev.yml`. The exact replacement —
working stand-in image (Option A), `profiles:` opt-in (Option B),
or commented block (Option C) — is `[NEEDS CLARIFICATION: ADR-001
deferred to design]`.

##### FR-B1-DUM-003 — Healthcheck still meaningful after fix

Whichever option is chosen, either (a) the `fsm-backend`
healthcheck (`curl http://localhost:8080/health`) MUST be
satisfiable by the replacement OR (b) the healthcheck MUST be
adjusted (or removed via Option B/C semantics) so that dependant
services do not wait indefinitely on a never-green
`fsm-backend`.

##### FR-B1-DUM-004 — Adopter swap-in instruction preserved

The template MUST retain a comment explaining how an adopter
substitutes their actual backend image (the existing comment block
at `docker-compose.dev.yml.tmpl:54..58` MUST be preserved or
rewritten — its intent must survive).

##### FR-B1-DUM-005 — Audit comment

The lines touched MUST be preceded by an audit comment :
```yaml
# ── T5.3.1 (b1-1-dev-up-matrix-fixes) — fsm-backend placeholder ──
```

#### Cluster 2 — `version:` obsolete attribute removal (FR-B1-DUM-020 → 025)

##### FR-B1-DUM-020 — `version:` key removed

The top-level `version: "3.8"` declaration at
`docker-compose.dev.yml.tmpl:25` MUST be removed. Compose v2
infers schema from filename without metadata loss.

##### FR-B1-DUM-021 — No `WARN attribute version is obsolete` on smoke

After FR-B1-DUM-020, running
`docker compose -f docker-compose.dev.yml config -q` against a
rendered fixture MUST produce no output on stderr containing
`attribute version is obsolete`. (Other warnings unrelated to
`version:` are out of scope.)

##### FR-B1-DUM-022 — No `version:` re-introduction in mirrors

The same key MUST be absent in **all four** synchronised copies
(see Cluster 3).

#### Cluster 3 — 4-copy mirror sync (FR-B1-DUM-040 → 050)

##### FR-B1-DUM-040 — Canonical → example mirror byte-identity (within edited region)

After the edits, `diff -u` between the canonical template and
`examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
MUST return zero across the **edited lines (former 25, former 60)
and their 2-line neighborhood**. Unrelated divergences elsewhere
(if any) are out of scope.

##### FR-B1-DUM-041 — Bundle-time mirror (`cli/assets/.forge/...`)

After `npm run bundle` (cli build), the bundled mirror at
`cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
MUST be byte-identical to the canonical template across the entire
file.

##### FR-B1-DUM-042 — Bundle-time example mirror (`cli/assets/examples/...`)

Same byte-identity rule MUST hold for
`cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
vs the example mirror at
`examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`.

##### FR-B1-DUM-043 — No new mirror

The fix MUST NOT introduce a fifth copy. All 4 paths above are the
exhaustive set ; harness asserts the count.

#### Cluster 4 — `task dev:up` E2E assertion (FR-B1-DUM-060 → 075)

##### FR-B1-DUM-060 — `dev:up` reaches steady state

Running `task dev:up` from a freshly scaffolded
`full-stack-monorepo` project (via `forge init … --archetype
full-stack-monorepo`) MUST exit 0 within the existing Taskfile
`dev-up-matrix` budget (per Task definition ; do not extend
timeouts).

##### FR-B1-DUM-061 — `docker compose ps` shows running services

After FR-B1-DUM-060, `docker compose ps --format json` MUST list
the non-backend infra services (`fsm-db`, `fsm-kong`, `fsm-signoz`,
`fsm-otel-collector`) in state `running` or `healthy`. The
`fsm-backend` state requirement is option-dependent
(`[NEEDS CLARIFICATION: ADR-001 deferred to design]` — Option A
expects running, Option B expects absent from default profile,
Option C expects absent commented).

##### FR-B1-DUM-062 — `task dev:down` cleans up

`task dev:down` MUST return exit 0 after FR-B1-DUM-061 and leave
no orphan container or volume bearing the fixture project's
`fsm-*` prefix.

##### FR-B1-DUM-063 — E2E location

The placement of this E2E cycle assertion — kept in the Taskfile
`dev-up-matrix` (opt-in) vs promoted to a blocking step in
`cli/test/e2e/archetypes-smoke.test.ts` — is
`[NEEDS CLARIFICATION: ADR-003 deferred to design]`.

#### Cluster 5 — Harness `t5-3-1.test.sh` (FR-B1-DUM-080 → 100)

##### FR-B1-DUM-080 — Harness file

A new file `.forge/scripts/tests/t5-3-1.test.sh` MUST exist,
executable bash, with `set -uo pipefail`, audit comment, `--level`
parsing, `_helpers.sh` source, manifest comment block — mirroring
the `t5-2.test.sh` / `t5-bin-server.test.sh` shape.

##### FR-B1-DUM-081 — ≥ 8 L1 grep-based tests

| Test ID                                                     | Asserts                                                                                                       |
|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| `_test_b1dum_l1_001_canonical_no_scratch`                   | canonical template `docker-compose.dev.yml.tmpl` does not contain `image: scratch`                            |
| `_test_b1dum_l1_002_canonical_no_version_key`               | canonical template does not contain a top-level `^version:` key                                               |
| `_test_b1dum_l1_003_audit_comment_present`                  | canonical template carries `T5.3.1 (b1-1-dev-up-matrix-fixes)` audit comment somewhere in the edited region   |
| `_test_b1dum_l1_004_mirror_example_byte_identity_edits`     | `diff` of edited region against `examples/forge-fsm-example/...` returns 0                                    |
| `_test_b1dum_l1_005_mirror_cli_assets_byte_identity_full`   | `diff -q` between canonical and `cli/assets/.forge/templates/...` returns 0 across the full file              |
| `_test_b1dum_l1_006_mirror_cli_assets_example_byte_identity`| `diff -q` between example mirror and `cli/assets/examples/forge-fsm-example/...` returns 0                    |
| `_test_b1dum_l1_007_four_copies_only`                       | `find` for `docker-compose.dev.yml.tmpl` under repo root returns exactly 4 paths (FR-B1-DUM-043)              |
| `_test_b1dum_l1_008_adopter_comment_preserved`              | the FR-B1-DUM-004 adopter swap-in comment block still appears verbatim or rewritten with same intent          |
| `_test_b1dum_l1_009_changelog_entry`                        | `CHANGELOG.md [Unreleased]` (or v0.4.0-rc.1/rc.2 section) references `b1-1-dev-up-matrix-fixes`               |

9 L1 anchors — meets ≥ 8 floor.

##### FR-B1-DUM-082 — L2 opt-in `FORGE_B1DUM_DOCKER=1`

At least 1 L2 test gated by `FORGE_B1DUM_DOCKER=1` AND
`command -v docker` :

- `_test_b1dum_l2_dev_up_cycle` — scaffolds a temp fixture via
  `forge init`, runs `task dev:up`, asserts `docker compose ps`
  shows the FR-B1-DUM-061 services, runs `task dev:down`, asserts
  no orphan containers remain. Skip-pass when either gate is
  unmet (mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`
  precedent per ADR-T5-OLR-005).

##### FR-B1-DUM-083 — Determinism

Re-running `bash t5-3-1.test.sh --level 1` twice in a row on a
clean tree MUST produce byte-identical stdout (modulo wall-clock
seconds). No randomness, no network, no Docker (L1).

##### FR-B1-DUM-084 — CI registration

`.github/workflows/forge-ci.yml` MUST register `t5-3-1.test.sh`
in the `harness` matrix immediately after `i5.test.sh` (latest
registered harness as of i5-compliance-workflow) with `--level 1`.

#### Cluster 6 — Documentation + plan inventory (FR-B1-DUM-110 → 120)

##### FR-B1-DUM-110 — CHANGELOG entry

`CHANGELOG.md` MUST gain a `### Fixed — full-stack-monorepo
docker-compose.dev.yml template hygiene (T5.3.1,
b1-1-dev-up-matrix-fixes)` block citing :

- `image: scratch` replacement (option chosen per ADR-001)
- `version: "3.8"` removal
- 4-copy mirror sync
- New harness `t5-3-1.test.sh`

##### FR-B1-DUM-111 — Plan inventory updated

The `Inventaire .forge/changes/` table in
`docs/new-archetypes-plan.md` MUST gain a row :
```
| b1-1-dev-up-matrix-fixes | archived | T5.3.1 (dev-up-matrix template hygiene) |
```

##### FR-B1-DUM-112 — Roadmap status line

`.forge/product/roadmap.md` Phase 3 / T5 row MUST gain a "T5.3.1
Done <date>" entry once archived. (Optional during `specified` →
mandatory at archive.)

### Non-Functional Requirements

##### NFR-B1-DUM-001 — Zero new external dep

No new entry in `cli/package.json`, no new Rust crate, no new Dart
package, no new tool prerequisite beyond what
`t5-otel-dartastic-realign` already required.

##### NFR-B1-DUM-002 — Harness wall-clock

`bash t5-3-1.test.sh --level 1` MUST complete in ≤ 2 s. L2
(`FORGE_B1DUM_DOCKER=1`) MAY take up to 180 s wall-clock (scaffold
+ `docker compose up` + healthcheck wait + `down`).

##### NFR-B1-DUM-003 — `forge-ci.yml` size

After registration, `.github/workflows/forge-ci.yml` MUST remain
≤ 300 lines (NFR-CI-002). Current 296 → matrix entry adds ~3
lines (one `- name:` + one inline comment + one `run:`) → 299 ;
remains within budget. Refactor if it doesn't.

##### NFR-B1-DUM-004 — No regression on prior harnesses

`verify.sh` PASS count MUST NOT decrease.
`constitution-linter.sh` OVERALL MUST remain PASS. Existing
harnesses (`t5-1`, `t5-2`, `t5-otel-dartastic`,
`i2..i6`, `j7`, `j8`, `k3`) MUST stay GREEN.

##### NFR-B1-DUM-005 — Atomic revertability

The change MUST be revertable via a single `git revert <merge-sha>`
without leaving the four template copies out-of-sync. (Tested by
the harness running pre- and post-revert in a separate worktree if
needed.)

##### NFR-B1-DUM-006 — Snapshot regen scope

Whether `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
must be regenerated is `[NEEDS CLARIFICATION: tied to ADR-001
choice — Option A modifies a rendered byte, Options B/C modify
the rendered structure]`. Resolution required before `tasks.md`.

### Open Decisions Deferred to `/forge:design`

| ID                | Decision                                                                                          | Owner             |
|-------------------|---------------------------------------------------------------------------------------------------|-------------------|
| `ADR-B1-DUM-001`  | `image: scratch` replacement — Option A (`traefik/whoami`) vs B (`profiles:`) vs C (commented)    | Atlas (Infra)     |
| `ADR-B1-DUM-002`  | `version:` removal — straight delete vs schema-version comment header                              | Atlas (Infra)     |
| `ADR-B1-DUM-003`  | E2E cycle placement — Taskfile-opt-in vs blocking `cli/test/e2e/archetypes-smoke.test.ts`         | Atlas + Eris      |

These three open questions are tracked in `open-questions.md`
(`Q-001`, `Q-002`, `Q-003`) at Status `open` until design resolves
each into an ADR.

---

## BDD Scenarios

> Article II (BDD) is N/A for this change (no user-facing feature),
> but the harness L2 scenario is documented in Given/When/Then for
> consistency with `t5-bin-server-deps` precedent.

### Scenario : `dev-up-matrix` cycle GREEN on freshly scaffolded fsm

```gherkin
Given a clean temporary directory $tmp
  And forge CLI built from current branch
  And docker daemon is running
  And FORGE_B1DUM_DOCKER=1 is exported
When `forge init smoke_b1dum --archetype full-stack-monorepo \
       --org dev.forge.test --target $tmp` is executed
  And `cd $tmp && task dev:up` is executed
Then exit code is 0
  And `docker compose ps --format json` lists fsm-db, fsm-kong,
      fsm-signoz, fsm-otel-collector in running/healthy state
  And no `WARN attribute version is obsolete` appears on stderr
When `task dev:down` is executed
Then exit code is 0
  And no container with the fsm-* prefix remains
```

---

## Anti-Hallucination Pass

| Surface                              | Verified via                                                                                                           |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| `image: scratch` at line 60          | `grep -n scratch .forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl` returned `60: image: scratch` |
| `version: "3.8"` at line 25          | Same `grep -n version:` returned `25: version: "3.8"`                                                                  |
| 4 mirror paths                       | `find . -name docker-compose.dev.yml.tmpl -not -path '*/node_modules/*'` returned exactly 4 paths                       |
| CI line count                        | `wc -l .github/workflows/forge-ci.yml` returned 296                                                                    |
| Upstream dep T5.3 archived           | git log shows `67a35bd chore(release): bump to v0.4.0-rc.1 — T5.3 Workiva → Dartastic OTel substitution`                |
| Harness frame pattern                | Read `t5-bin-server.test.sh` FR-T5BSD-070..073 cluster ; same shape applied as FR-B1-DUM-080..084                       |
| L2 opt-in env var precedent          | `FORGE_LIVE_RUN_DOCKER=1` documented in `t5-otel-live-run` ADR-T5-OLR-005 ; same gate pattern reused as `FORGE_B1DUM_DOCKER` |

No symbol asserted in this spec is unsourced. Three explicit
`[NEEDS CLARIFICATION: ...]` markers are open against ADR-pending
decisions ; they MUST be resolved by `/forge:design` before
`/forge:plan` is run, per Article III.4.

---

*Next : `/forge:design b1-1-dev-up-matrix-fixes`.*
