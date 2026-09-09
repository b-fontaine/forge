# Specs — `b9-7-web-ci`

**Namespace** : `FR-B9-7-*`, `NFR-B9-7-*`, `ADR-B9-7-*`.
Consolidated target on archive : `.forge/specs/mobile-pwa-first.md`.

---

## Functional Requirements

### FR-B9-7-001 — a per-surface web workflow exists and renders

`2.0.0/.github/workflows/web-pwa-ci.yml.tmpl` MUST exist and MUST be listed in
`scaffold-plan.yaml` with `target: .github/workflows/web-pwa-ci.yml` and
`substitute: true`. A template that exists but is not in the plan renders
nothing — the failure mode this requirement exists to catch.

### FR-B9-7-002 — `dorny/paths-filter@v3`, never `on.paths`

The workflow MUST gate its work with `dorny/paths-filter@v3` on `web-pwa/**`,
and MUST NOT use `on.<event>.paths`. Per `ci-workflows.md` ADR-002: a workflow
skipped by native path filtering publishes no required status, so branch
protection cannot tell "not applicable" from "never ran".

### FR-B9-7-003 — Node comes from `.nvmrc`, not a literal

The Node setup step MUST use `actions/setup-node@v4` with
`node-version-file: web-pwa/.nvmrc`. A duplicated literal would drift from the
surface's declared target.

This is load-bearing, not hygiene: `t5-qwik-cli-ignore-dep` established that
`qwik build` hands ` --pretty` to **npm**, which npm ≥ 12 rejects
(`EUNKNOWNCONFIG`) while npm 9/10/11 accept it. `.nvmrc` pins Node 24, which
ships npm ≤ 11, so the build exits 0. Pinning CI to any newer Node would turn
this workflow red for a reason that has nothing to do with the code under test.

### FR-B9-7-004 — gate ordering

Steps MUST run in the `ci-workflows.md` order: static analysis → build → Forge
gates last (`verify.sh`, then `constitution-linter.sh`).

Concretely: `npm run build.types` (tsc, no emit) → `npm run build` →
`bash .forge/scripts/verify.sh` → `bash .forge/scripts/constitution-linter.sh`.

The standard's step 1 (format) and step 3 (tests) have **no tooling in this
surface** — `web-pwa/package.json` declares no formatter, no linter and no test
runner. Their absence is recorded, not silently skipped (NFR-B9-7-004): the
standard permits a subset (the infra workflow swaps step 3), but not a wrong
order among the steps that do exist.

### FR-B9-7-005 — build output is uploaded, not deployed

The workflow MUST upload `web-pwa/dist/` via `actions/upload-artifact@v4` and
MUST NOT contain a deploy step, a hosting-provider action, or a reference to a
deploy secret. Maintainer decision, 2026-09-09 (ADR-B9-7-003).

### FR-B9-7-006 — a required-check summary that cannot pass vacuously

The workflow MUST declare a `summary` job that `needs` the build job and fails
unless its result is `success` or `skipped`. `skipped` counts as success because
that is the paths-filter miss, which ADR-002 defines as the normal
not-applicable outcome.

### FR-B9-7-007 — `continue-on-error: true` is absent

Forbidden by `ci-workflows.md` § Failure semantics.

### FR-B9-7-008 — the byte-equivalence gate is updated, not weakened

`b9-2.test.sh::T-007` MUST gain `--exclude=web-pwa-ci.yml`, with a comment
stating (a) why the legacy render has no counterpart, and (b) that `--exclude`
matches a basename at any depth — repeating B.9.3's warning rather than assuming
the next reader knows it.

### FR-B9-7-009 — harness registered in CI

`.forge/scripts/tests/b9-7.test.sh` MUST exist and be registered in
`forge-ci.yml` under the `harness` job at `--level 1`.

### FR-B9-7-010 — CHANGELOG entry

`CHANGELOG.md` `[Unreleased]` MUST carry a `b9-7-web-ci` entry.

---

## Non-Functional Requirements

### NFR-B9-7-001 — the Flutter surface is untouched

No file under `lib/`, `ios/`, `android/`, `test/`, nor `mobile-ci.yml.tmpl`, may
change. Asserted by `b9-2.test.sh::T-007` remaining GREEN with only the one new
exclusion.

### NFR-B9-7-002 — CI line budget

`forge-ci.yml` is at 418 lines against a 420 cap (NFR-CI-002, asserted by
`c1.test.sh:746`). Registering this harness costs exactly one line → 419. No
lock-step bump across the five budget-asserting harnesses is needed.

### NFR-B9-7-003 — harness budget

`b9-7.test.sh --level 1` MUST be grep/YAML-static only: no network, no Docker,
no `npm`. Budget ≤ 3 s.

### NFR-B9-7-004 — absent tooling is declared, not implied

The workflow header MUST state that format and test steps are absent because the
surface declares no such tooling, and name the follow-up. A reader must not
conclude from the file that the surface is format-clean or tested.

---

## ADRs

### ADR-B9-7-001 — a separate workflow, not more jobs in `mobile-ci.yml`

**Context.** The web jobs could extend the existing workflow or live in their own.

**Decision.** Their own: `web-pwa-ci.yml`.

**Rationale.** Three reasons, in order of weight. (1) It is the sibling
convention — `full-stack-monorepo` ships `forge-backend` / `forge-frontend` /
`forge-infra` / `forge-integration`, and `event-driven-eu` splits the same way;
one workflow per surface is how this framework already models multi-surface
archetypes. (2) `mobile-ci.yml` is byte-frozen against the `mobile-only` render
(FR-B9-2-004); editing it costs a second exclusion in T-007 and permanently ends
the Flutter surface's byte-equivalence. (3) The two surfaces have different
triggers, runners and toolchains; merging them means per-job path filtering
inside one workflow for no gain.

**Consequence.** Two required checks instead of one. Documented in the template
header so an adopter configuring branch protection sees both.

### ADR-B9-7-002 — `npm install`, not `npm ci`

**Context.** `npm ci` is the usual CI choice and is strictly faster.

**Decision.** `npm install`.

**Rationale.** `npm ci` **requires** a lockfile and exits non-zero without one. A
freshly scaffolded project has no `package-lock.json` — the scaffolder renders
`package.json` only. `npm ci` would therefore fail on the adopter's very first
push, which is the same day-one-red failure mode that got the deploy job dropped.

**Consequence.** Builds are not lockfile-reproducible until the adopter commits a
lockfile. Accepted for a scaffold; the template header says so, and once a
lockfile exists `npm install` honours it.

### ADR-B9-7-003 — build and upload; do not deploy

**Context.** B.9.7 as originally written adds a `pwa-deploy` job targeting
Cloudflare Pages, Vercel or an OVH-managed channel, "au choix". No Forge
standard constrains the choice — checked against `forbidden-components-rules.md`
and `compliance-tiers.md`, neither of which mentions hosting.

**Decision (maintainer, 2026-09-09).** No deploy job. Build, then
`actions/upload-artifact@v4` on `web-pwa/dist/`.

**Rationale.** A scaffolded deploy job needs adopter secrets to exist before the
first push, so it is red on day one for every adopter who has not yet chosen a
host — and `pwa.yaml::PWA-RULE-003` already places deploy-time secrets with the
adopter. Scaffolding a vendor choice also embeds it: removing it later is a
migration, whereas adding it is a two-step edit against a working artifact.

**Consequence.** The archetype ships no path to a live preview URL. The template
header points at the artifact and states plainly that wiring a host is an adopter
step, so the gap is visible rather than assumed covered.
