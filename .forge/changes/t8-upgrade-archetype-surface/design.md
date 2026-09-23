# Design — `t8-upgrade-archetype-surface`

## The defect is two lines, and one wrong assumption

```
:291  owned_list=$(_a7_resolve_owned_paths "$FORGE_REPO_ROOT")
:300  src_right="$FORGE_REPO_ROOT/$rel"
```

The resolver was **already** root-parameterised — the bug was never in it. `_a7_main`
simply never passed anything but the framework root, because A.7 was written for
`default`, the one archetype that IS the framework asset tree. Everything rendered has
been outside that model since.

So the fix is small where it matters and careful where it is risky: give `_a7_main` a
second mode, leave the first untouched.

## Three functions

- `_a7_project_archetype` — archetype mode iff the manifest names an archetype that has
  a `scaffold-plan*.yaml` **and** the project ships its own owned-paths file. Both a
  `default` project and an archetype render carry a `.forge/` and an owned-paths file, so
  the file's presence cannot discriminate; the plan can, because the plan is precisely
  what makes RIGHT reproducible. `mobile-only` has a template dir and no plan, and renders
  no manifest at all, so it never reaches the branch.
- `_a7_project_owned_paths` — delegates to the existing resolver with the target as root.
- `_a7_render_archetype <archetype> <manifest> <templates_root>` — absolutizes the plan's
  `source:` paths into a throwaway plan (overlay.sh hardcodes its own archetype dir; every
  wrapper does this), renders through `overlay.sh`, deletes the rendered
  `scaffold-manifest.yaml`, echoes the directory.

`templates_root` is the seam that lets the same function produce RIGHT (from the repo) and
BASE (from an extracted snapshot).

## Why BASE is rendered rather than read

The snapshot is framework-shaped: it stores
`.forge/templates/archetypes/<a>/<v>/pubspec.yaml.tmpl`, not `pubspec.yaml`. Looking up an
adopter-layout path inside it finds nothing, silently, and degrades every file to a 2-way
conflict — which is what `forge-migrate-flagship` still does, resolving 1 of 36 paths.
Rendering maps template layout to project layout the one way the project was built.

## Degradation, deliberately

Three levels, each measured rather than assumed:

| situation | behaviour |
|---|---|
| RIGHT render fails | say so, fall back to the framework path — **never** an empty owned list, which would report a clean upgrade having merged nothing (NFR-T8UAS-001) |
| BASE render fails | documented 2-way fallback (FR-UP-003); an unchanged file still classifies `unchanged` because LEFT equals RIGHT |
| no snapshot at all | same 2-way fallback |

The middle row is not hypothetical: today's snapshots cannot render, because they drop
every dotfile. The upgrade still succeeds with zero conflicts — which is how we know the
degrade path is the one being exercised.

## Verification

1. Three L1 cells RED against the current driver — detection, the merge surface, and the
   framework-paths exclusion. The third needed an **anti-vacuity floor** before it could
   fail: with the function missing the surface is empty, and an empty surface contains no
   framework path either, so it passed while nothing existed.
2. A hermetic render cell: the rendered tree carries the declared files, no `.tmpl`
   survives, no placeholder survives, and the rendered manifest is gone.
3. An opt-in end-to-end cell (`FORGE_A7_LIVE=1`): render a real `mobile-pwa-first`
   project, commit it, upgrade it, require zero conflicts and exit 0.
4. The full `a7` suite green, with the framework-shaped cells unchanged.
