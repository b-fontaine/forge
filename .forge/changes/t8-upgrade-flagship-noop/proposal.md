# Proposal — `t8-upgrade-flagship-noop`

`t8-upgrade-archetype-surface` (`473cd36`, fix-forward `ee9a745`) gave `forge upgrade` an
archetype mode. Its records say the flagship "keeps the old behaviour". Measured on a
fresh render, it does not.

## What a real run did

`bin/forge-init-fsm-2.0.0.sh` renders a project, which is committed and then upgraded
**without** `--dry-run`:

```
files unchanged:  1
files upgraded:   0
files preserved:  0
files conflicted: 0
files skipped:    548        → exit 0
```

The run merged nothing. It still stamped the manifest `archetype_version: 2.0.1`, gave it
a new `template_set_sha`, and appended a "clean" `upgrade_history` entry. On a tree
rendered and upgraded from the same commit, the driver from before `473cd36` returns
**exit 8**: 548 unchanged, 8 conflicts. That failed, but honestly. The new run succeeded,
and lied in the manifest. That is the silent manifest damage NFR-T8UAS-001 and
FR-T8UAS-011 were written to prevent.

## Why

`init.sh:208` copies the framework's `.forge/` into every flagship render (minus its
runtime state: `changes/`, `_memory/`, `specs/`, `product/`). That includes the
framework's **root** `.forge/framework-owned-paths.yml`, byte for byte.
`_a7_project_archetype` only asked two things: does the archetype have a scaffold plan,
and does the project have that file? The flagship answers yes to both. So the driver took
the framework's own declaration (`.claude/agents/**`, `bin/*`, …) as an archetype
declaration, and rendered RIGHT from the archetype template, which contains none of those
paths. Result: 548 of 549 skipped.

ADR-T8UAS-001 anticipated half of this. It noted that "a default init copies the
framework's [file], so the file's presence alone cannot discriminate; the plan can". The
plan cannot either: the flagship has one.

## A sibling on the same path

The one archetype that enters the mode on purpose also skipped a file in silence. On a
fresh `mobile-pwa-first` render, `files skipped: 1` is
`android/app/src/main/kotlin/<domain>/PlayIntegrityService.kt`, a path the project
declares framework-owned. `_a7_render_archetype` left the `{{reverse_domain_path}}`
directory literal in RIGHT, where the wrapper relocates it after rendering (its step 3).
`t8-upgrade-archetype-surface` Q-002 attributed that skip to "a declared path the project
does not have yet". That is impossible: such a path never enters the owned list.

## Scope

**In:**
- archetype mode requires that the archetype's **plan renders the declaration**
  (`.forge/framework-owned-paths.yml` is one of its targets);
- `_a7_render_archetype` reproduces the wrapper's Kotlin package relocation;
- in archetype mode, a declared path the render cannot produce is **reported**, not
  folded into a count;
- the records this falsifies: plan §0.19, FR-T8UAS-001, ADR-T8UAS-001, Q-002, CHANGELOG.

**Added by the independent review** (FR-T8UFN-006 to -009): SemVer validation of
`archetype_version`; the name gate applied to the snapshot path; no manifest update on a
conflicted run without `--force` (FR-UP-007); a single cleanup trap for temporary trees.
All four sit on the same driver path, and the review reproduced each one.

**Out:** the ADR-014 **union** of the framework and archetype declarations
(`t8-upgrade-archetype-surface` Q-005: it changes every archetype's surface and needs a
decision per archetype); the flagship's own 8 conflicts on a fresh render, a pre-existing
defect this brick brings back into plain sight; the snapshots' missing dotfiles
(`t8-upgrade-archetype-surface` Q-001).

## Negative scope

MUST NOT change the counts or exit codes for `default`, `ai-native-rag` or
`event-driven-eu` projects. None of them enters archetype mode, before or after, and each
is measured both ways. MUST NOT refuse an upgrade merely because a declared path is absent
from the render: the framework may legitimately stop shipping a file, and a glob can
match an adopter's own file.
