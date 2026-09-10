# Proposal — `b9-9-migrate-mobile-pwa`

`bin/forge-migrate-mobile-pwa.sh` — take a `mobile-only / 1.0.0` install and add the
PWA surface without touching the native tree.

## The contract, derived by execution rather than read off the plan

Rendered both archetypes from the same inputs and diffed the trees:

```
Only in <ported>/.forge:            scaffold-manifest.yaml
Only in <ported>/.github/workflows: web-pwa-ci.yml
Only in <ported>:                   oidc-provider.json
Only in <ported>:                   web-pwa            (23 files)
```

**26 additions, and zero files differ.** The Flutter surface is byte-identical
between a `mobile-only` render and a `mobile-pwa-first` one.

That is not a happy accident: `ADR-B9-1-004` predicted it. `mobile-only`'s single
`- id: app / path: .` maps 1:1 onto `mobile-pwa-first`'s `app` layer, same id, same
path — so the migration *cannot* need to rewrite native files. This change confirms
the prediction by measurement before relying on it.

## What that buys, and what it changes about the design

`forge-migrate-flagship.sh` sources `forge-upgrade.sh`'s `_a7_*` 3-way merge engine
because its migration genuinely modifies existing files. Here nothing is modified, so
a merge engine would be machinery for a case that cannot arise on a pristine install
— and the case that *can* arise on a diverged one (the adopter already has a
`web-pwa/`) is better served by refusing than by merging into it.

So: **additive-only, with collision refusal**. Exit 8 on a collision unless `--force`,
matching the flagship's 0/2/5/7/8 envelope.

## Two constraints the flagship precedent does not cover

**A `mobile-only` install has no `scaffold-manifest.yaml`.** Only
`.forge/framework-owned-paths.yml`. So `b8-10b`'s approach — read `project_name` /
`reverse_domain` out of the manifest — is unavailable. Both are derivable from the
project itself: `pubspec.yaml`'s `name:` and `android/app/build.gradle.kts`'s
`namespace`. Deriving is also *more correct* than a stored value: if the adopter has
changed their applicationId, the migration should follow them.

**Render, never copy.** `b8-10b` established this the hard way — the flagship
migration shipped 36 raw `.tmpl` files with live placeholders into adopters' projects.
This one renders through `overlay.sh`, so there is one implementation of the
placeholder semantics and the output is the same bytes `forge init` would produce.

## Scope

**In:** the script; a filtered render of the archetype plan's 25 additive entries; the
`.forge/scaffold-manifest.yaml` a migrated project needs; a harness; `--dry-run`.

**Out:** `docs/MIGRATION-PATHS.md`, which is B.9.10's deliverable and is listed as
such in the plan.

## Negative scope

MUST NOT modify any file the target already has — that is the whole contract, and the
harness asserts it by comparing the native tree before and after. MUST NOT touch
`overlay.sh`, the archetype plan, or the frozen `mobile-only/1.0.0` snapshot.
