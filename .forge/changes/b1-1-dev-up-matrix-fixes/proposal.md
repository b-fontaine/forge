# Proposal: b1-1-dev-up-matrix-fixes
<!-- Created: 2026-05-19 -->
<!-- Schema: default -->
<!-- Audit: T5.3.1 (docs/new-archetypes-plan.md §0.4) -->

## Problem

The `full-stack-monorepo` archetype template
`.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
shipped by `b1-foundations` / `b1-delivery` (T2 P1) carries two
pre-existing latent bugs that block the `dev-up-matrix` smoke leg of
`task validate` :

1. **`image: scratch` placeholder at line 60** (`fsm-backend`
   service). Docker rejects `scratch` as a reserved image name, so
   `task dev:up` fails immediately — the dependent services
   (`fsm-kong`, `fsm-signoz`, `fsm-otel-collector`, the frontend)
   never come up. The template comment ("replace with project image
   once built") makes this an explicit TODO placeholder, but the
   placeholder itself is non-functional and breaks every smoke run.
2. **`version: "3.8"` obsolete attribute at line 25**. Compose v2 has
   deprecated the top-level `version:` key and emits a warning
   (`the attribute version is obsolete`) on every invocation. Not a
   blocker, but it pollutes smoke output and adopter projects inherit
   the same warning.

These bugs were **latent**, not regressions : they survived since T2
P1 (2026 early) because the upstream legs of `task validate`
(`smoke-with-toolchains` calling `flutter pub get` on a web-only
Workiva package, mvdan/sh syntax errors, `.env` bootstrap absence)
failed *before* `dev-up-matrix` was ever reached. T5.3
(`t5-otel-dartastic-realign`, archived 2026-05-18) fixed those
upstream legs (Workiva → Dartastic, Taskfile mvdan/sh fixes, `.env`
bootstrap) and exposed `dev-up-matrix` for the first time.

T5.3 carried the upstream fixes (cf. plan §0.3 "First fixes carried
in T5.3"). T5.3.1 (this change) carries the downstream fixes now
visible — strictly template-hygiene, no link to the Workiva →
Dartastic substitution. Bundling them with T5.3 would have diluted
the audit narrative ("Workiva → Dartastic") and made atomic revert
impossible, per the Forge pattern already applied in T5.1.E
(`t5-cargo-pin-refresh` and `t5-bin-server-deps` as fix-forwards
distinct from `cli-trust-harness`).

## Solution

Template hygiene pass on `docker-compose.dev.yml.tmpl` across the
**four synchronised copies** (canonical + example mirror + cli/assets
bundle + cli/assets example mirror) :

1. **Replace `image: scratch`** with a functional placeholder. Three
   options surface in plan §0.4 (Option A working stand-in image —
   `traefik/whoami` or equivalent ; Option B Docker Compose
   `profiles: ["backend"]` opt-in ; Option C comment-out
   `fsm-backend` + dependants). **Arbitration deferred to
   `/forge:design`** where Atlas (Infrastructure Architect) will
   recommend with ADR-001 trade-offs.
2. **Remove `version: "3.8"`** top-level key. Compose v2 inference
   from filename only — no metadata loss.
3. **Add an e2e assertion** that `task dev:up` + `docker compose ps`
   + `task dev:down` cycle GREEN on the `full-stack-monorepo`
   archetype. Two options (Taskfile-only opt-in vs blocking e2e in
   `cli/test/e2e/`) deferred to `/forge:design` ADR-003.
4. **`task validate` GREEN end-to-end** as the release gate.

Release vehicle : either piggyback on **v0.4.0-rc.1** (if T5.3.1
lands before the rc.1 npm tag) or ship as **v0.4.0-rc.2** patch.
Decision deferred to release time depending on landing speed.

## Scope In

- Edit `.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
  (canonical) — lines 25 + 60.
- Mirror the same edits to the **three downstream copies** :
  - `examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
  - `cli/assets/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
  - `cli/assets/examples/forge-fsm-example/.forge/templates/archetypes/full-stack-monorepo/docker-compose.dev.yml.tmpl`
- New harness `t5-3-1.test.sh` under `.forge/scripts/tests/` (or
  extension of `archetypes-smoke.test.ts`) exercising the
  `task dev:up` + `docker compose ps` + `task dev:down` cycle.
- `CHANGELOG.md` entry under v0.4.0-rc.1 (or rc.2) section.
- `forge-ci.yml` matrix update if a new harness file is introduced.

## Scope Out (Explicit Exclusions)

- **No structural rewrite** of `docker-compose.dev.yml.tmpl`. Kong /
  SigNoz / OBI / Coroot / OTel-collector layout stays as shipped by
  T5 (`t5-otel-stack`, archived 2026-05-10). T5.3.1 is hygiene, not
  re-architecture B.8.
- **No touch on `mobile-only` smoke**. T5.3 left mobile-only
  `flutter analyze` GREEN ; T5.3.1 is scoped to `full-stack-monorepo`
  template only.
- **No constitutional or standard change**. T5.3.1 introduces no new
  standard, no FR onto existing standards, no `linter_rule:` addition.
- **No new agent or persona**. Atlas advises in design but the work
  is purely templated YAML edits.
- **No Workiva / Dartastic touch**. The OTel migration is closed in
  T5.3.

## Impact

- **Users affected** : every adopter who runs `task dev:up` after
  scaffolding `full-stack-monorepo` (currently 100 % broken on
  `image: scratch`). Adopters who customised the line manually are
  not affected.
- **Technical impact** : 1 template file (×4 copies), 1 harness, 1
  CHANGELOG entry, 1 CI matrix entry if new harness. No Rust, no
  Dart, no proto, no constitution surface touched.
- **Dependencies** : depends on T5.3 (`t5-otel-dartastic-realign`)
  having greened `smoke-with-toolchains` so `dev-up-matrix` is even
  reachable. Already satisfied (archived 2026-05-18).
- **Forward unblocks** : no downstream change is blocked on T5.3.1.
  T6 / B.8 will rewrite the template top-to-bottom anyway. T5.3.1
  closes the dette so the **interim** `1.0.0` template stays usable
  for adopters until T6 lands.

## Constitution Compliance

- **Article I (TDD)** : RED-GREEN-REFACTOR applies. A failing
  `t5-3-1.test.sh::dev_up_matrix_green` assertion lands FIRST (RED),
  the template edits follow to turn it GREEN. No "too simple to test"
  exemption — the bug is exactly that the harness was never run.
- **Article II (BDD)** : N/A. No user-facing feature ; pure
  template hygiene. The `.forge/standards/global/bdd-rules.md`
  `feature_kind: user-facing` predicate does not fire.
- **Article III (Specs Before Code)** : confirmed. FRs land in
  `specs.md` before any template byte is moved. The
  `[NEEDS CLARIFICATION:]` discipline applies if Atlas surfaces
  unresolved trade-offs in design.
- **Article IV.2 (No Complete Rewrites — "History must be preserved")** :
  `b1-foundations` and `b1-delivery` (the original template authors,
  archived in T2 P1) are NOT modified. T5.3.1 edits the **live
  template** at `.forge/templates/...` ; archived files stay
  untouched. A `.forge-update-notes` forward-pointer in each archived
  change is **not required** here (the archived `proposal.md` /
  `specs.md` / `design.md` are content-historical, not contract
  surfaces — the template is the contract surface).
- **Article VI (Flutter Architecture)** : N/A. No Dart code touched.
- **Article VII (Rust Architecture)** : N/A. No Rust code touched.
- **Article VIII (Infrastructure)** : N/A. Kong / Connect layout
  unchanged.
- **Article XII (Governance — review cadence)** : N/A. No standard
  birth / review.

## Open Decisions Deferred to `/forge:design`

1. **ADR-001** : choice between Option A (`traefik/whoami` stand-in),
   Option B (`profiles: ["backend"]` opt-in), Option C (commented
   block). Atlas to recommend with healthcheck + adopter-friction
   trade-offs.
2. **ADR-002** : Compose `version:` removal — straight delete vs
   schema-version comment header. Likely trivial but ADR captures
   intent.
3. **ADR-003** : e2e test placement — Taskfile-only `dev-up-matrix`
   leg (opt-in, current location) vs promote to blocking
   `cli/test/e2e/archetypes-smoke.test.ts` step (would need Docker
   daemon in CI runner). Trade-off : CI speed vs depth of coverage.

## Effort & Release

- **Effort** : `S` to `M` (~½ day to 1 day depending on ADR-001
  choice).
- **Release target** : v0.4.0-rc.1 piggyback OR v0.4.0-rc.2 patch
  (decision at release time).
- **Critères de réussite** :
  - `task validate` GREEN end-to-end on the same branch
    (full-stack-monorepo + mobile-only smoke).
  - `task dev:up` + `docker compose ps` + cleanup loop GREEN on
    full-stack-monorepo.
  - No regression on existing harnesses (verify.sh +
    constitution-linter + t5-1 + t5-2 + t5-otel-dartastic preserved).

---

*Next : `/forge:specify b1-1-dev-up-matrix-fixes`.*
