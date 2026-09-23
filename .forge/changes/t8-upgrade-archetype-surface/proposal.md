# Proposal — `t8-upgrade-archetype-surface`

`t7-qwik-deps-refresh` Q-007: `forge upgrade` never reads the
`.forge/framework-owned-paths.yml` a project ships, so a template bump never reaches an
existing project. Measured end-to-end this time, not read.

## What a real run does today

Rendered a `mobile-pwa-first` project with its own wrapper, committed it, ran
`forge upgrade --dry-run` against it — an **untouched project, freshly produced by the
very framework doing the upgrade**:

```
files unchanged:  0
files upgraded:   0
files preserved:  507
files conflicted: 49        → exit 8
```

`pubspec.yaml` and `web-pwa/package.json` appear **nowhere** in that run.

The cause is one line. `_a7_resolve_owned_paths "$FORGE_REPO_ROOT"` (`:291`) reads the
**framework's** root manifest — 556 paths like `.claude/agents/*.md` and
`.forge/templates/**` — and `src_right="$FORGE_REPO_ROOT/$rel"` (`:300`) takes each RIGHT
from the framework tree. So the driver merges Forge's own files into a project whose
`.forge/` is a *render*, not a copy of Forge. The project's own declaration — 10 paths,
including the two the `t7-flutter-deps-refresh` CHANGELOG claims are "now framework-owned"
— is never opened.

A.7 was designed against the only archetype that is framework-shaped (`default`, a
file-copy of the asset tree). Every rendered archetype has been outside its model since.

## Scope

**In:** an **archetype mode** in `bin/forge-upgrade.sh`, entered when the project's
manifest names an archetype that has a scaffold plan:

- owned paths come from the **project's** `.forge/framework-owned-paths.yml`;
- RIGHT is **rendered** from that archetype's current template (through `overlay.sh`, the
  one implementation of placeholder semantics — the `_b810_render_right` precedent);
- BASE is **rendered from the snapshot's** template tree when the snapshot exists, so an
  untouched file that the framework moved classifies as `upgraded` rather than as a
  conflict; absent snapshot degrades to the documented 2-way fallback (FR-UP-003);
- the framework's own 556 paths are **not** merged into an archetype project.

Plus the record corrections Q-007 requires: `t7-flutter-deps-refresh`'s "the bump now
reaches existing projects" is false as written and is retracted where it is stated.

**Out:** the full archetype-aware upgrade for projects with **no** snapshot or **no**
plan (`mobile-only` renders no manifest at all and exits 2 before reaching any of this);
rewriting the frozen snapshots; `forge-migrate-flagship`'s own BASE lookup, which has the
same root cause in a second place; the dotfile blindness in `_a7_resolve_owned_paths`'s
glob. Each recorded as an open question with its measurement.

## Negative scope

MUST NOT change behaviour for framework-shaped (`default`) projects — that is the path
`a7.test.sh` covers today. MUST NOT write the rendered manifest into the target (the
`_b810_render_right` data-loss lesson). MUST NOT make an upgrade destructive: a failed
render degrades to the existing behaviour rather than to an empty owned list.
