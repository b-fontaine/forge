# Open questions — `t8-upgrade-archetype-surface`

## Q-001: every scaffold snapshot is missing its dotfiles, so BASE cannot be rendered

- **Status**: open
- **Raised in**: `evidence.md § P-7`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

`bin/forge-snapshot.sh` collects files with `glob.glob(pattern, recursive=True)`, which
never matches a name beginning with a dot. Measured on one archetype:
`mobile-pwa-first` has **9 dotfiles in the repository and 0 in its snapshot**
(`.envrc.example`, `.nvmrc.tmpl`, `.gitignore`, the `.github/workflows/*` templates …).

Two consequences. The one this brick meets: `_a7_render_archetype` against an extracted
snapshot aborts on the first missing file, so BASE degrades to the 2-way fallback and a
framework bump reads as a conflict instead of an upgrade. The one that is worse: a BASE
recovered from such a snapshot has been incomplete for every archetype since snapshots
shipped, so `forge upgrade` has been 2-way-merging those paths all along without saying so.

Rebuilding the snapshots changes what every existing adopter recovers as BASE, and
`full-stack-monorepo/1.0.0` is `.sha256`-pinned with harness guards. That is its own
brick, with its own decision about the frozen ones.

## Q-002: a declared path that does not yet exist in the project is skipped, silently

- **Status**: open
- **Raised in**: `evidence.md § P-5`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

The merge surface is the project's declaration expanded by globbing **the project's own
tree**, so a declared path the framework has added but the project does not have yet is
counted as `skipped` rather than delivered. The measured run shows `files skipped: 1` for
exactly that reason.

For a pin bump — the case this brick exists for — the file always exists. For a genuinely
new framework file it does not, and "skipped" is the wrong answer. Fixing it means
resolving the surface against the *render* as well as the project, which changes what an
upgrade may create rather than merge; that deserves its own decision.

> **Correction (2026-09-23, `t8-upgrade-flagship-noop` evidence P-3).** The measurement
> cited above does not show this. The owned list is expanded against the project's tree,
> so a path the project lacks never enters it and is counted nowhere. At best it is
> reported by FR-T8UAS-011's "did not resolve" line, which compares the number of entries
> with the number of resolved files. A glob that expands to several files can hide the
> shortfall. The `files skipped: 1` was
> `PlayIntegrityService.kt`, missing from RIGHT because the render left
> `{{reverse_domain_path}}/` unrelocated; that is fixed by FR-T8UFN-003. The question
> itself still stands: a file the framework adds later reaches no existing project.

## Q-003: `forge-migrate-flagship` has the same BASE-layout defect, in a second place

- **Status**: open
- **Raised in**: `specs.md § ADR-T8UAS-002`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

The reason BASE is *rendered* here rather than read is that a snapshot stores
`.forge/templates/archetypes/<a>/<v>/pubspec.yaml.tmpl`, not `pubspec.yaml`. Reported by
the investigation lane and not re-measured here: `bin/forge-migrate-flagship.sh` phase 2
looks up adopter-layout paths inside that framework-layout snapshot and resolves **1 of
36**, silently 2-way-falling-back for the other 35. Same root cause, same fix shape
(`_a7_render_archetype` is liftable), different driver.

## Q-004: `mobile-only` can never be upgraded, and nothing says so

- **Status**: open
- **Raised in**: `proposal.md § Scope`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

`mobile-only` renders no `.forge/scaffold-manifest.yaml`, so `forge upgrade` exits 2
("target is not a Forge project") before any of this. It also has a template directory but
no scaffold plan, so it could not enter archetype mode even with a manifest. Either it
gains both, or it should be documented as upgrade-incapable — it is currently a
`legacy_alias` that adopters can still render.

## Q-005: only one archetype can enter the mode this brick added

- **Status**: open
- **Raised in**: `specs.md § FR-T8UAS-001`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

Archetype mode requires a project-side `.forge/framework-owned-paths.yml`, and measured
across the five scaffold plans, exactly one renders it:

```
mobile-pwa-first/scaffold-plan.yaml            2 references
ai-native-rag/scaffold-plan.yaml               0
event-driven-eu/scaffold-plan.yaml             0
full-stack-monorepo/scaffold-plan.yaml         0
full-stack-monorepo/scaffold-plan-2.0.0.yaml   0
```

So an untouched `ai-native-rag` render still returns exit 8 — the review measured 326
preserved and 230 conflicts — which is exactly the defect this brick exists to fix,
untouched for three archetypes out of four.

Closing it is not a line of code: a declaration says which files the framework owns and
which the adopter does, and that answer differs per archetype (`ai-native-rag` has a Rust
backend and a Qwik surface; the flagship has three layers). Writing one by guess would
hand adopters merges over files they consider theirs — the consent problem `b9-10` Q-001
already flagged for `pubspec.yaml`.

The honest interim position is the one now written into FR-T8UAS-001 and the CHANGELOG:
the fix holds where a project declares a surface, and three archetypes do not yet.

## Q-006: a bogus archetype name falls back to a 556-path framework merge

- **Status**: open
- **Raised in**: `evidence.md § P-11`
- **Raised on**: 2026-09-23
- **Raised by**: @bfontaine

### Question

The traversal gate refuses to treat `../../../../planted` as an archetype, which is
right — but the run then takes the framework path and reports 556 conflicts and exit 8,
rather than saying the manifest is malformed. That is the pre-existing behaviour for any
project the driver does not recognise, and it is safe; it is also unhelpful. Whether a
manifest naming an unknown or malformed archetype should abort with a clear message
instead is a small decision, deliberately not taken inside a security fix.

> **Correction (2026-09-23, `t8-upgrade-flagship-noop` FR-T8UFN-007).** "It is safe" was
> false. On the framework path, the raw name was still joined into
> `.forge/scaffold-snapshots/<archetype>/<version>.tar.gz` and handed to `tar`. A tarball
> planted where that path led became BASE, which turned an adopter's edited file into a
> silent `upgraded`. The independent review reproduced this end to end. The name gate now
> applies before the snapshot path is built, so a refused name reads no snapshot at all.
> The question itself still stands: whether a malformed name should abort outright.
