# Design — `b9-9-migrate-mobile-pwa`

## The contract, measured before it was relied on

`ADR-B9-1-004` predicted the migration would be purely additive. Rendering both
archetypes from identical inputs and diffing confirms it:

```
Only in <ported>/.forge:            scaffold-manifest.yaml
Only in <ported>/.github/workflows: web-pwa-ci.yml
Only in <ported>:                   oidc-provider.json
Only in <ported>:                   web-pwa            (23 files)
Files differing: 0
```

26 additions, zero modifications. Confirming the prediction cost one command and
turned the central design assumption from inherited into established.

## Consequence: no merge engine (ADR-B99-001)

`forge-migrate-flagship.sh` sources `forge-upgrade.sh`'s `_a7_*` because its migration
rewrites files. Here nothing is rewritten, so the engine would serve a case that
cannot arise on a pristine install. On a diverged one — the adopter wrote their own
`web-pwa/` — merging framework templates into their work is worse than refusing.

So: **render to a staging dir, check collisions, then add**. Exit 8 on collision
without `--force`, matching the sibling's 0/2/5/7/8 envelope. The frozen
`mobile-only/1.0.0` snapshot is therefore not read by this script; it stays the
reverse target `forge upgrade` uses, which is what B.9.8 froze it for.

## The additive set is filtered, not duplicated

The entries come from the archetype's own `scaffold-plan.yaml`, selected by
`target` under `web-pwa/` plus the two root additions — 25 of its 73. A second
hand-maintained list is what made `b8-10b` need a coverage guard; here there is
nothing to drift from, and `T-025` asserts the filter still yields 25.

Sources are absolutized in the same pass, because `overlay.sh:128` hardcodes its
`ARCHETYPE_DIR` to `full-stack-monorepo` and would otherwise resolve them against the
flagship tree — the documented `forge-init-mobile-pwa-first.sh` trick.

## Substitution values: derived, not stored (ADR-B99-002)

A `mobile-only` install has **no** `.forge/scaffold-manifest.yaml` — only
`framework-owned-paths.yml`. So `b8-10b`'s "read them from the manifest" does not
apply. `pubspec.yaml`'s `name:` gives the project name;
`android/app/build.gradle.kts`'s `namespace` gives the reverse domain.

Deriving is better than a stored value here, not just necessary: if the adopter
changed their `applicationId` after scaffolding, the Gradle file is what their build
uses. Either value missing ⇒ exit 7 naming it — never an empty substitution, which
produces a file that looks rendered and is silently wrong.

## Proof

A migrated tree versus a native `forge init --archetype mobile-pwa-first` render:

```
Files ported/.forge/scaffold-manifest.yaml and mig-src/.forge/scaffold-manifest.yaml differ
--- differences: 1
```

**Byte-identical except the manifest**, and the manifest differs only in
`scaffold_date`, `scaffold_plan_sha` and `template_set_sha` — the last two because
the render ran from the filtered plan, which is what actually happened.
`archetype`, `archetype_version`, `project_name`, `reverse_domain` and `root_module`
all match.

## What the harness asserts, and where

Four guards in `b9-2.test.sh` rather than a new harness: `forge-ci.yml` is at 419/420
and B.9.11 still has to register `b9.test.sh`. `b9-2` also already owns the
scaffold-plan this filters and provides `_render_legacy` — the exact fixture needed.

| test | asserts |
|---|---|
| T-024 | shape, `--help` exit 0, missing `--target` exits 2 |
| T-025 | the filter still yields 25 entries, 23 of them `web-pwa/` |
| T-026 | migrates a real render: surface arrives rendered, **and the native tree hashes identically before and after** |
| T-027 | a re-run refuses (7 or 8) rather than re-rendering |

T-026 is the one that matters: it hashes every pre-existing file before and after.
`b8-10b` shipped raw templates into adopters' projects because no test ever inspected
migration output.
