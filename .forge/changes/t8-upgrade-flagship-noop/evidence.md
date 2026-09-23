# Evidence — `t8-upgrade-flagship-noop`

2026-09-23. Every render and every upgrade ran in a scratch directory outside the
repository. The repository's `git status` was checked before and after each probe.

---

## P-1 — a fresh flagship render, upgraded for real

`bin/forge-init-fsm-2.0.0.sh --target … --project-name probe --reverse-domain
io.forge.probe` (rc=0), then `git init` + commit, then
`bin/forge-upgrade.sh --target … --to-version 2.0.1 --verbose`, **without** `--dry-run`:

```
files unchanged:  1
files upgraded:   0
files preserved:  0
files conflicted: 0
files skipped:    548                                  → exit 0

archetype_version: 2.0.0 → 2.0.1
template_set_sha:  dd3efa99… → 8f461791…
upgrade_history:   + { counts: { skipped: 548, unchanged: 1, … }, to_version: 2.0.1 }
```

The run merged nothing and wrote a clean upgrade into the manifest anyway. The same tree
with the driver as of `39ac1d1` (before `473cd36`):

```
files unchanged: 547 · conflicted: 9 · skipped: 0      → exit 8
```

Eight of those conflicts are `bin/forge-{install,lint,rehash-architecture-doc,snapshot,upgrade}.sh`,
`LICENSE`, `NOTICE` and `CLAUDE.md`: framework-owned paths that a flagship render does not
carry, or carries in its own form. They are a pre-existing defect (Q-005), and a visible
one. **The ninth, `.forge/scripts/tests/a7.test.sh`, is an artefact of this measurement**,
caught by the independent review (P-8). The render was taken before this brick edited the
harness, and RIGHT was taken after. A render and an upgrade from the same tree give **548
unchanged / 8 conflicts**, with either driver (P-10).

## P-2 — the mechanism

```
$ cmp <render>/.forge/framework-owned-paths.yml .forge/framework-owned-paths.yml
(identical)
```

`init.sh:208` runs `cp -R "$FORGE_ROOT_SRC/.forge" "$target_abs/.forge"`, so every flagship
render carries the framework's **root** declaration. `_a7_project_archetype` checked that
the archetype has a scaffold plan and that the file exists. The flagship passes both
checks, so the driver entered archetype mode. RIGHT then became the overlay render of
`scaffold-plan-2.0.0.yaml`, which contains none of `.claude/**`, `bin/*`, `docs/*`, …, and
548 of the 549 paths resolved from the project were skipped.

Measured with the driver at `HEAD` (`ee9a745`), fresh renders, `--dry-run`:

| render | rc | unchanged | conflicted | skipped |
|---|---|---|---|---|
| `full-stack-monorepo` 1.0.0 (`bin/forge-init-fsm.sh`) | 0 | 1 | 0 | **548** |
| `full-stack-monorepo` 2.0.0 | 0 | 1 | 0 | **548** |
| `mobile-pwa-first` 2.0.0 | 0 | 9 | 0 | **1** |

The 1.0.0 render also carries a byte-identical copy of the root file.

## P-3 — the `mobile-pwa-first` skip is the Kotlin directory

The owned list resolved from the project, checked against a RIGHT produced by
`_a7_render_archetype`:

```
MISSING IN RIGHT: android/app/src/main/kotlin/io/forge/probe/PlayIntegrityService.kt
render:  …/android/app/src/main/kotlin/{{reverse_domain_path}}/PlayIntegrityService.kt
```

`overlay.sh` uses a plan's `target:` verbatim. The wrapper relocates the placeholder
directory afterwards (its step 3); the upgrade's render did not. Only one plan has a
placeholder in a `target:` path: `mobile-pwa-first`, with two entries, both under that
directory.

This is the `files skipped: 1` that `t8-upgrade-archetype-surface` evidence P-5 shows and
its Q-002 attributes to "a declared path the project does not have yet". That explanation
cannot be right: the owned list is expanded against the project's own tree, so a path the
project lacks never enters it. It is counted nowhere. The only report it gets is the
FR-T8UAS-011 "did not resolve" line.

## P-4 — RED

Three L1 cells were written before the driver changed, and each failed for its own reason:

```
✗ test_copied_framework_declaration_is_not_archetype_mode
    a flagship 2.0.0 project holding a COPY of the framework's declaration entered archetype mode (got 'full-stack-monorepo')
    a flagship 1.0.0 project holding a COPY of the framework's declaration entered archetype mode (got 'full-stack-monorepo')
✗ test_archetype_render_relocates_path_placeholders
    PlayIntegrityService.kt is not at the reverse-domain path the wrapper gives it
    a {{placeholder}} survived in a rendered path name: android/app/src/main/kotlin/{{reverse_domain_path}}
✗ test_archetype_unproducible_path_is_reported
    the unproducible path was skipped without being reported on stderr
```

With `FORGE_A7_LIVE=1`, the two end-to-end cells failed too:

```
✗ test_archetype_upgrade_clean_on_untouched_render   rc=0 conflicts=0 skipped=1
✗ test_flagship_upgrade_is_not_a_silent_noop         rc=0 unchanged=1 skipped=548
```

The first of these had passed on the same tree for the previous brick. It asserted
`rc=0` and `conflicts=0`, and never looked at `skipped`.

A fourth cell, `test_archetype_plan_selection_is_versioned`, was added **after** the
refactor, when mutation 4 of P-6 turned nothing red. It characterises the plan-selection
helper this change extracts. Against the pre-change driver it cannot run at all, because
the helper does not exist there. So it has no RED before GREEN: it is a guard, and P-6
proves it bites. (The first version of this section said four cells were written first.
The review showed that was false.)

## P-5 — GREEN

`a7.test.sh` with `FORGE_A7_LIVE=1`: **39 / 39**. `shellcheck --severity=warning` is
clean on the driver and on the harness.

The fresh renders of P-2, upgraded with the fixed driver:

| render | mode | rc (dry / real) | unchanged | preserved | conflicted | skipped |
|---|---|---|---|---|---|---|
| `full-stack-monorepo` 2.0.0 | framework | 8 / 8 | 547 ¹ | 0 | 9 ¹ | **0** |
| `full-stack-monorepo` 1.0.0 | framework | 8 | 482 | 5 | 69 | **0** |
| `mobile-pwa-first` 2.0.0 | archetype | 0 / 0 | **10** | 0 | 0 | **0** |
| `ai-native-rag` 1.0.0 | framework | 8 / 8 | 0 | 326 | 230 | 0 |
| `event-driven-eu` 1.0.0 | framework | 8 / 8 | 0 | 395 | 161 | 0 |
| `default` | — | 2 / — | no `scaffold-manifest.yaml`: refused before any mode logic |

The last three rows match the numbers measured before the change (NFR-T8UFN-002).
¹ This render predates the harness edit, which is where the ninth conflict comes from
(see P-1). The final tree gives 548 / 8 (P-10).

## P-6 — mutation probes

Each fix was reverted in turn with an anchored replacement (the script asserts the anchor
matches exactly once, so a probe that never applies cannot pass silently). The full
suite, including the LIVE cells, ran after each one:

| mutation | cells that went red |
|---|---|
| detection: plan check always true | `test_copied_framework_declaration_is_not_archetype_mode`, `test_flagship_upgrade_is_not_a_silent_noop` |
| relocation disabled | `test_archetype_render_relocates_path_placeholders`, `test_archetype_upgrade_clean_on_untouched_render` |
| skip report disabled | `test_archetype_unproducible_path_is_reported` |
| versioned plan never selected | `test_archetype_plan_selection_is_versioned` |

The fourth mutation turned nothing red until the characterisation cell was added. The
refactor had shipped with no test pinning it. The driver was restored and its sha256
checked after every probe.

## P-7 — regression (T6.1)

The whole CI replay ran on the working tree, after `npm run bundle`, the same step the
`harness` job runs first. The array was extracted from `forge-ci.yml` itself rather than
retyped, so no harness could be left out. All **82** harness entries PASS. `verify.sh`
RESULT: PASS (its one warning is the pre-existing "no lib/ or src/"). `constitution-linter.sh`
107 PASS / 0 FAIL. `shellcheck --severity=warning` is clean over `.forge/scripts` and
`bin`, the two directories the `lint` job scans. `forge-ci.yml` is still 421 lines
(NFR-T8UFN-001).

P-7 covers the tree as it stood before the review. The final replay is P-11.

## P-8 — independent review (Article V)

Four lanes ran in separate contexts: the driver by reproduction on real renders, security,
the new cells, and the written claims. Every finding then went through adversarial
verification: three votes for a blocker or major finding, one for the rest. **33 findings,
30 confirmed, none blocking.** Three findings were rejected; each had misread what the LIVE
flagship cell asserts.

What the review caught that this brick had missed:

| finding | kind | outcome |
|---|---|---|
| a **raw** `archetype` still reached `.forge/scaffold-snapshots/<archetype>/<v>.tar.gz` in framework mode, so a planted tarball became BASE and turned an adopter's file into a silent `upgraded`. Reproduced end to end, and upgraded to major by its verifier | security, pre-existing | fixed, FR-T8UFN-007 |
| `archetype_version` reached the plan and snapshot paths unvalidated; `_a7_check_version_compat` only compares the first dot-field | security, latent | fixed, FR-T8UFN-006 |
| a conflicted run without `--force` stamped the manifest, which FR-UP-007 **forbids**. This brick's Q-001 had called it "A.7's design" | spec violation, pre-existing | fixed, FR-T8UFN-008; Q-001 answered |
| the extracted snapshot leaked (~6 MB) on every archetype-mode run, because each new trap replaced the last | pre-existing | fixed, FR-T8UFN-009 |
| an unreadable plan now switched the mode in silence | regression of this brick | reported, FR-T8UFN-001 |
| the `--verbose` listing echoed the target's file names raw (ESC/CR) | new surface | `%q`, FR-T8UFN-004 |
| the relocation gate depended on `LC_ALL`, and could not be reached through `overlay.sh` | nit | ASCII gate in its own tested helper |
| the detection cell passed a content-comparing detector; ADR-003 was tested in dry runs only; the `{{` guard covered one archetype; the report count was not anchored | test strength | cells strengthened (P-9) |
| "547 / 9"; "four cells written first"; "ADR-014 appliqué à la lettre"; "whole .forge/"; "the only report it gets"; the LIVE cell's described checks | written claims | corrected |

## P-9 — RED, GREEN and mutation probes for the review round

Against the driver as it was when the review ran, the new or strengthened L1 cells gave
**8 RED**, each for its own reason:

```
✗ test_archetype_plan_selection_is_versioned   a version containing '/' selected a plan (…/scaffold-plan-2.0.0.d/../../elsewhere/other.yaml)
✗ test_kotlin_relocation_gates_reverse_domain  (helper absent)
✗ test_archetype_unproducible_path_is_reported the unproducible paths were skipped without being reported (new wording)
✗ test_unreadable_plan_is_reported             an unreadable plan switched the project to framework mode in silence
✗ test_malformed_version_is_refused            '2.0.0.d/../../x' rc=8 · '../2.0.0' rc=7 · '2.0' rc=8
✗ test_invalid_archetype_never_reaches_a_snapshot   files upgraded: 1   (the planted BASE was used)
✗ test_conflicted_run_does_not_stamp_manifest  archetype_version=2.0.1, history=1 after rc=8
✗ test_upgrade_leaves_no_temp_dirs             …/tmpd/forge-up-base-Qupngf left behind
```

GREEN: `a7.test.sh` **46 / 46**, with and without `FORGE_A7_LIVE=1`. `shellcheck
--severity=warning` is clean.

Eleven mutations were applied to a **copy** of the repository. Each anchor is asserted to
match exactly once, and the full suite runs after every mutation:

| mutation | cells that went red |
|---|---|
| detection compares content instead of reading the plan | `test_copied_framework_declaration_is_not_archetype_mode`, `test_unreadable_plan_is_reported` |
| version gate removed from the helper | `test_archetype_plan_selection_is_versioned` |
| version gate removed from `_a7_main` | `test_malformed_version_is_refused` |
| name gate removed from the snapshot path | `test_invalid_archetype_never_reaches_a_snapshot` |
| per-directory trap restored | `test_upgrade_leaves_no_temp_dirs` |
| conflicted runs stamped again | `test_conflicted_run_does_not_stamp_manifest` |
| unreadable plan silent again | `test_unreadable_plan_is_reported` |
| raw `echo` in the listing | `test_archetype_unproducible_path_is_reported` |
| relocation gate always true | `test_kotlin_relocation_gates_reverse_domain` |
| report emitted in dry runs only | `test_archetype_unproducible_path_is_reported` |
| a plan targets `src/{{reverse_domain_path}}/x.rs` | `test_every_plan_placeholder_path_is_relocated` |

## P-10 — fresh renders of the final tree

Each archetype was rendered with its wrapper from the final tree, committed, and upgraded
as a dry run and then for real:

| render | rc (dry / real) | unchanged | upgraded | preserved | conflicted | skipped | manifest after |
|---|---|---|---|---|---|---|---|
| `full-stack-monorepo` 2.0.0 | 8 / 8 | 548 | 0 | 0 | 8 | 0 | 2.0.0, no history |
| `full-stack-monorepo` 1.0.0 | 8 / 8 | 482 | 66 | 5 | 3 | 0 | 1.0.0, no history |
| `mobile-pwa-first` 2.0.0 | 0 / 0 | **10** | 0 | 0 | 0 | **0** | 2.0.1, 1 entry |
| `ai-native-rag` 1.0.0 | 8 / 8 | 0 | 0 | 326 | 230 | 0 | 1.0.0, no history |
| `event-driven-eu` 1.0.0 | 8 / 8 | 0 | 0 | 395 | 161 | 0 | 1.0.0, no history |

The 8 flagship 2.0.0 conflicts are `CLAUDE.md`, `LICENSE`, `NOTICE` and
`bin/forge-{install,lint,rehash-architecture-doc,snapshot,upgrade}.sh`. No run printed a
skip report, as expected, since no run skipped a path.

## P-11 — final regression (T7.5)

The final tree after `npm run bundle`, with the harness array read from `forge-ci.yml`
itself: **82 / 82 PASS**. `verify.sh` RESULT: PASS (its only warning is the existing "no
lib/ or src/"). `constitution-linter.sh` 107 PASS / 0 FAIL. `shellcheck
--severity=warning` is clean over `.forge/scripts` and `bin`. `a7.test.sh` 46 / 46 with
`FORGE_A7_LIVE=1`. `forge-ci.yml` is still 421 lines (NFR-T8UFN-001).
