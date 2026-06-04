<!-- Audit: B.8.14 (b8-14-promotion-prep) -->

# Flip Runbook — B.8.14 point-of-no-return (post-window follow-up)

The follow-up brick `b8-14-promotion-flip` executes these steps **after** the
§VIII.1 amendment's ≥ 7-day public discussion window closes. This prepare brick
does NONE of them. Order matters: the amendment ratifies **first** (removing Kong
before ratification = a constitutional violation, `2.0.0.yaml:17-31`).

## Pre-conditions
- The ≥ 7-day public discussion window on `amendment-viii-1.md` has elapsed.
- The full harness suite + `verify.sh` + `constitution-linter.sh` are green on `main`.

## Steps (in order)

1. **Close the discussion** and record the outcome on the public thread.
2. **Ratify** (`GOVERNANCE.md §"Amendment Process"` step 3) — BDFL ratification
   (Phase actuelle).
3. **Apply the amendment** (step 4) to `.forge/constitution.md`:
   - Replace §VIII.1 with the proposed Envoy text (`amendment-viii-1.md`).
   - Add the Amendment #2 row to the `## Amendments` table.
   - Bump the `**Version**` line `v1.1.0 → v2.0.0`.
   - Update `.forge/templates/change.yaml` + every archetype `.forge.yaml.tmpl`
     `constitution_version` to `2.0.0`.
   - **Framework version**: stay on the `0.4.0` MINOR line with a `### BREAKING`
     CHANGELOG note — pre-1.0 carve-out **`VERSIONING.md:70-73`** (NOT the post-GA
     lockstep table at `:48-56`); the framework MAJOR follows at GA.
4. **Promote the 2.0.0 schema** (`.forge/schemas/full-stack-monorepo/2.0.0.yaml`):
   `stage: candidate → stable`, set **`scaffoldable: true`** (from `false`). Update the 2.0.0
   template READMEs that say "scaffoldable: false until B.8.14" / "Kong remains the
   constitutional API gateway".
5. **Execute the removal manifest** (`removal-manifest.yaml`) in the 2.0.0
   **scaffold composition** (NOT by editing the frozen 1.0.0 base): the 2.0.0
   scaffold = 1.0.0 base MINUS the `scaffold_composition` targets (`infra/kong/`,
   `fsm-kong`, `FSM_KONG_ADMIN_PORT`, the scaffold-plan kong entry, the REST-bridge
   routes, the Taskfile kong wording) PLUS the additive 2.0.0 overlay. Remove/
   supersede the `framework_standard` target `.forge/standards/infra/kong.md`
   (→ `gateway.yaml`).
6. **Land the deferred B.8.3.b scaffolder guard** — `forge init` gains
   versioned-schema selection (pick 2.0.0 stable) + the runtime guard refusing any
   `scaffoldable: false` schema.
7. **Activate the 1.0.0 deprecation** (see below).
8. **Re-run** the full suite + `verify.sh` + `constitution-linter.sh`; confirm the
   `b8-14.test.sh` negative held-guards now legitimately flip (they are retired or
   inverted by the flip brick) and the new state is green. Independent review.

## t4 material-path (if §11/§12.1 of ARCHITECTURE-TARGET.md are updated)
`docs/ARCHITECTURE-TARGET.md` is sha256-pinned by `t4.test.sh::_test_t4_023`
(B.8.13). Updating its §11/§12.1 Kong/DBOS narrative is a **material** edit ⇒ the
follow-up MUST take the **material-path**: a fresh Forge change superseding parts
of `t4-adr-ratification`, then `bin/forge-rehash-architecture-doc.sh` to re-pin
(REHASH-LOG convention). NOT record-only. (B.8.13 used record-only because it was
documentation-only; the flip's constitutional realignment is material.)

## 1.0.0 deprecation announcement (DRAFT — activate at step 7)

> **Deprecation notice.** With the 2.0.0 promotion, `full-stack-monorepo` **1.0.0**
> enters a **T + 6-month** (6 mois) deprecation window. During the window 1.0.0
> remains buildable/maintained (security + critical fixes) and migratable via
> `docs/MIGRATIONS.md`; after it, 1.0.0 is unsupported (per `VERSIONING.md`
> support policy — pre-1.0 "only the latest 0.y.z is supported"). New scaffolds
> default to 2.0.0. EOL date = flip date + 6 months.

Destinations at activation: a `### Deprecated` block in `CHANGELOG.md` + a support
row in `VERSIONING.md` / the `GOVERNANCE.md` release-communication policy.
